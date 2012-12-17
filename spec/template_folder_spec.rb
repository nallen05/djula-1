
require 'rubygems'
require 'bundler/setup'
require 'minitest/autorun'

require 'djula'


module Djula describe Djula::TemplateFolder do
  
  
  ## internal parser / compiler tests
  
  describe '.extract_block_form' do

    it 'should get block source from template file (including start & end tags)' do
      src = 'before block <% djula_block "foo" %> in block <% djula_endblock "foo" %> after block'
      should_extract = '<% djula_block "foo" %> in block <% djula_endblock "foo" %>'
      TemplateFolder.extract_block_form(src,'foo').must_equal should_extract
    end
    
    it 'should also work with symbols as block names (not just names in the form of strings)' do
      src = 'before block <% djula_block :foo %> in block <% djula_endblock :foo %> after block'
      should_extract = '<% djula_block :foo %> in block <% djula_endblock :foo %>'
      TemplateFolder.extract_block_form(src,'foo').must_equal should_extract
    end
    
    it 'should should work if there are multiple blocks' do
      src = '1<% djula_block "foo" %>2<% djula_endblock "foo" %>3<% djula_block :bar %>4<% djula_endblock :bar %>5'
      should_extract_foo = '<% djula_block "foo" %>2<% djula_endblock "foo" %>'
      TemplateFolder.extract_block_form(src,'foo').must_equal should_extract_foo
      should_extract_bar = '<% djula_block :bar %>4<% djula_endblock :bar %>'
      TemplateFolder.extract_block_form(src,'bar').must_equal should_extract_bar      
    end
    
  end
  
  describe '.maybe_replace_block' do

    it 'should not replace anything if the "from" template does not share any blocks with the "to" template' do
      to_src = '1<% djula_block "a" %>2<% djula_endblock "a" %>3'
      from_src = '4<% djula_block "b" %>5<% djula_endblock "b" %>6'      
      TemplateFolder.maybe_replace_block(to_src,from_src,'a').must_equal to_src
    end
    
    it 'should replace the target block in the "to" template with the related block from the "from" template' do
      to_src = '1<% djula_block "a" %>2<% djula_endblock "a" %>3'
      from_src = '4<% djula_block "a" %>5<% djula_endblock "a" %>6'
      should_rewrite_to = '1<% djula_block "a" %>5<% djula_endblock "a" %>3'
      TemplateFolder.maybe_replace_block(to_src,from_src,'a').must_equal should_rewrite_to
    end
    
  end
  
  describe '.get_template_blocks_list' do

    it 'should return an empty array if there are no blocks in the template' do
      src = '1<%= 1+1 %>3'
      TemplateFolder.get_template_blocks_list(src).must_equal []
    end
    
    it 'should return the list of blocks in a template' do
      src = '1<%= 1+1 %>3<% djula_block "a" %>4<% djula_endblock "a" %>5<% djula_block "b" %>6<% djula_endblock "b" %>7'
      TemplateFolder.get_template_blocks_list(src).must_equal ['a','b']
    end
    
  end
  
  describe '.get_src_before_extends_form' do
    
    it 'should return the src before and <% djula_extends .. %> form' do
      src = '1<%= 1+1 %>3<% djula_extends "foo/template.html.erb" %>4'
      before_extends_src = '1<%= 1+1 %>3'
      TemplateFolder.get_src_before_extends_form(src).must_equal before_extends_src
    end
    
  end
  
  describe '.rewrite_extending_template' do

    it 'should fill in a block from the base template from the source template, as well as append the source template src before the extends form' do
      base_src = '1<% djula_block "a" %>2<% djula_endblock "a" %>3'
      source_src = '4<% djula_extends "this/example.html.erb" %>5<% djula_block "a" %>6<% djula_endblock "a" %>7'
      should_rewrite_to = '14<% djula_block "a" %>6<% djula_endblock "a" %>3'
      TemplateFolder.rewrite_extending_template(source_src,base_src).must_equal should_rewrite_to
    end


    it 'should should also work for multiple blocks' do
      base_src = '1<% djula_block "a" %>2<% djula_endblock "a" %>3<% djula_block "b" %>4<% djula_endblock "b" %>5<% djula_block "c" %>6<% djula_endblock "c" %>7'
      source_src = '8<% djula_extends "this/example.html.erb" %>9<% djula_block "a" %>10<% djula_endblock "a" %>11<% djula_block "c" %>12<% djula_endblock "c" %>13<% djula_block "d" %>14<% djula_endblock "d" %>15'
      should_rewrite_to = '18<% djula_block "a" %>10<% djula_endblock "a" %>3<% djula_block "b" %>4<% djula_endblock "b" %>5<% djula_block "c" %>12<% djula_endblock "c" %>7'
      TemplateFolder.rewrite_extending_template(source_src,base_src).must_equal should_rewrite_to
    end
    
  end
  
  describe '.get?' do

    it 'should return nil if the template object does not exist' do
      src = "1<%= 1+1 %>3"
      template_name = '/aa/11.html.erb'      
      assets = {template_name => src}
      
      f = Djula::TemplateFolder.new nil
      f.update_asset_hash assets
      f.get('/bb/22.html').must_equal nil
    end

    it 'should return the compile template object if it exists' do
      src = "1<%= 1+1 %>3"
      template_name = '/aa/11.html.erb'      
      template_key =  '/aa/11.html'
      assets = {template_name => src}
      
      f = Djula::TemplateFolder.new nil
      f.update_asset_hash assets      
      (!!f.get(template_key)).must_equal true # slightly hacky...
    end
    
  end
  
  describe '.template_extends?' do

    it 'should return nil if the template is not extending another template' do
      src = "1<%= 1+1 %>3"
      template_name = '/aa/11.html.erb'
      TemplateFolder.template_extends?(src,template_name).must_equal nil
    end

    it 'should return the name of the extended template (already absolutized template name)' do
      src = "1<% djula_extends '/bb/22.html.erb' %>2<% djula_block 'a' %>3<% djula_endblock 'b' %>4"
      template_name = '/aa/11.html.erb'
      TemplateFolder.template_extends?(src,template_name).must_equal '/bb/22.html.erb'
    end
    
    it 'should return the name of the extended template (absolutizing template name in the process)' do
      src = "1<% djula_extends 'bb/22.html.erb' %>2<% djula_block 'a' %>3<% djula_endblock 'b' %>4"
      template_name = '/aa/11.html.erb'
      TemplateFolder.template_extends?(src,template_name).must_equal '/aa/bb/22.html.erb'
    end
    
  end
  
  describe '#get_template_stack' do
    
    it "should return only the source template if it does not extend any other templates" do
      src = "1<%= 1+1 %>3"
      template_name = '/aa/11.html.erb'      
      assets = {template_name => src}
      
      x = Djula::TemplateFolder.new nil
      x.update_asset_hash assets      
      x.get_template_stack(template_name).must_equal [template_name]    
    end
    
    it "should return the source & extended template if the source template extends another template" do

      base_src = '1<% djula_block "a" %>2<% djula_endblock "a" %>3<% djula_block "b" %>4<% djula_endblock "b" %>5<% djula_block "c" %>6<% djula_endblock "c" %>7'
      base_template_name = '/aa/bb/22.html.erb'
      
      source_src = '8<% djula_extends "bb/22.html.erb" %>9<% djula_block "a" %>10<% djula_endblock "a" %>11<% djula_block "c" %>12<% djula_endblock "c" %>13<% djula_block "d" %>14<% djula_endblock "d" %>15'
      source_template_name = '/aa/11.html.erb'
      
      assets = {
        base_template_name => base_src,
        source_template_name => source_src
      }
      
      x = Djula::TemplateFolder.new nil
      x.update_asset_hash assets
      x.get_template_stack(source_template_name).must_equal [base_template_name,source_template_name]
    end
   
    it "should work with chains of more than one template" do
      base_src = '1<% djula_block "a" %>2<% djula_endblock "a" %>3<% djula_block "b" %>4<% djula_endblock "b" %>5<% djula_block "c" %>6<% djula_endblock "c" %>7'
      base_template_name = '/aa/bb/22.html.erb'
      
      source_src = '8<% djula_extends "bb/22.html.erb" %>9<% djula_block "a" %>10<% djula_endblock "a" %>11<% djula_block "c" %>12<% djula_endblock "c" %>13<% djula_block "d" %>14<% djula_endblock "d" %>15'
      source_template_name = '/aa/11.html.erb'
      
      assets = {
        base_template_name => base_src,
        source_template_name => source_src
      }
      
      x = Djula::TemplateFolder.new nil
      x.update_asset_hash assets
      x.get_template_stack(source_template_name).must_equal [base_template_name,source_template_name]
    end 
    
  end
  
  describe '#precompile_standalone_src' do

    it 'should return the same src if the template is not extending another template' do      
      src = "1<%= 1+1 %>3"
      template_name = '/aa/11.html.erb'      
      assets = {template_name => src}
      
      x = Djula::TemplateFolder.new nil
      x.update_asset_hash assets
      x.precompile_standalone_src(template_name).must_equal src
    end

    it 'should return a rewritten version of the source to combine the template with the template it extends' do      

      base_src = '1<% djula_block "a" %>2<% djula_endblock "a" %>3<% djula_block "b" %>4<% djula_endblock "b" %>5<% djula_block "c" %>6<% djula_endblock "c" %>7'
      base_template_name = '/aa/bb/22.html.erb'
      
      source_src = '8<% djula_extends "bb/22.html.erb" %>9<% djula_block "a" %>10<% djula_endblock "a" %>11<% djula_block "c" %>12<% djula_endblock "c" %>13<% djula_block "d" %>14<% djula_endblock "d" %>15'
      source_template_name = '/aa/11.html.erb'
      
      assets = {
        base_template_name => base_src,
        source_template_name => source_src
      }
      
      should_rewrite_to = '18<% djula_block "a" %>10<% djula_endblock "a" %>3<% djula_block "b" %>4<% djula_endblock "b" %>5<% djula_block "c" %>12<% djula_endblock "c" %>7'
      
      x = Djula::TemplateFolder.new nil
      x.update_asset_hash assets
      x.precompile_standalone_src(source_template_name).must_equal should_rewrite_to
    end

    it 'should work if the extended template is also extending another template' do 
      base_src_0 = '1<% djula_block "a" %>2<% djula_endblock "a" %>3<% djula_block "b" %>4<% djula_endblock "b" %>5<% djula_block "c" %>6<% djula_endblock "c" %>7'
      base_template_name_0 = '/aa/bb/cc/33.html.erb'
      
      base_src_1 = '8<% djula_extends "cc/33.html.erb" %>9<% djula_block "b" %>10<% djula_endblock "b" %>11<% djula_block "d" %>12<% djula_endblock "d" %>13'
      base_template_name_1 = '/aa/bb/22.html.erb'

      source_src = '14<% djula_extends "bb/22.html.erb" %>15<% djula_block "a" %>16<% djula_endblock "a" %>17<% djula_block "e" %>18<% djula_endblock "e" %>19'
      source_template_name = '/aa/11.html.erb'
      
      assets = {
        base_template_name_0 => base_src_0,
        base_template_name_1 => base_src_1,
        source_template_name => source_src
      }
      
      should_rewrite_to = '1814<% djula_block "a" %>16<% djula_endblock "a" %>3<% djula_block "b" %>10<% djula_endblock "b" %>5<% djula_block "c" %>6<% djula_endblock "c" %>7'
            
      x = Djula::TemplateFolder.new nil
      x.update_asset_hash assets
      x.precompile_standalone_src(source_template_name).must_equal should_rewrite_to
    end  
  end
  
  ## dealing with files
  
  describe '#looks_like_template_file?' do
    it 'recognizes files that look like templates' do
      src = "1<%= 1+1 %>3"
      template_name = '/aa/11.html.erb'      
      assets = {template_name => src}
      
      x = Djula::TemplateFolder.new nil
      x.update_asset_hash assets

      x.looks_like_template_file?("foo").must_equal false  
      x.looks_like_template_file?("foo.html").must_equal false
      x.looks_like_template_file?("foo.html.erb").must_equal "foo.html.erb"
      
      x.looks_like_template_file?("/a/folder/foo").must_equal false  
      x.looks_like_template_file?("/a/folder/foo.html").must_equal false
      x.looks_like_template_file?("/a/folder/foo.html.erb").must_equal "/a/folder/foo.html.erb"
    end
      
  end
  
  describe '#should_ignore_filename?' do
    it 'recognizes filenames it should ignore' do
      src = "1<%= 1+1 %>3"
      template_name = '/aa/11.html.erb'      
      assets = {template_name => src}
      
      x = Djula::TemplateFolder.new nil
      x.update_asset_hash assets
      
      x.should_ignore_filename?(".").must_equal "."
      x.should_ignore_filename?("..").must_equal ".."

      x.should_ignore_filename?("foo").must_equal false  
      x.should_ignore_filename?(".foo").must_equal ".foo"
      x.should_ignore_filename?("_foo").must_equal "_foo"
      
      x.should_ignore_filename?("/a/folder/foo").must_equal false  
      x.should_ignore_filename?("/a/folder/.foo").must_equal "/a/folder/.foo"
      x.should_ignore_filename?("/a/folder/_foo").must_equal "/a/folder/_foo"
    end
      
  end
  
  
end end