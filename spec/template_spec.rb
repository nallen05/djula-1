

require 'rubygems'
require 'bundler/setup'
require 'minitest/autorun'

require 'djula'


module Djula describe Djula::TemplateFolder do
  
  
  ## rendering templates
  
  describe '#render' do

    it 'should render simple erb' do      
      src = "0<% x=1+1 %>1<%= x %>3"
      template_name = '/aa/11.html.erb'
      template_key = '/aa/11.html'
      assets = {template_name => src}
      
      f = Djula::TemplateFolder.new nil
      f.update_asset_hash assets
      x = f.get template_key
      x.render.must_equal "0123"
    end
    
    it 'should turn hash arguments into symbols' do
      src = "0<%= @foo %>1<%= @bar %>3"
      template_name = '/aa/11.html.erb'
      template_key = '/aa/11.html'      
      assets = {template_name => src}
      
      f = Djula::TemplateFolder.new nil
      f.update_asset_hash assets
      x = f.get template_key
      x.render(:foo => 'a', :bar => 'b').must_equal "0a1b3"
    end
    
    it 'should render templates that extend another template' do      

      base_src = '1<% djula_block "a" %>2<% djula_endblock "a" %>3<% djula_block "b" %>4<% djula_endblock "b" %>5<% djula_block "c" %>6<% djula_endblock "c" %>7'
      base_template_name = '/aa/bb/22.html.erb'
      
      source_src = '8<% djula_extends "bb/22.html.erb" %>9<% djula_block "a" %>10<% djula_endblock "a" %>11<% djula_block "c" %>12<% djula_endblock "c" %>13<% djula_block "d" %>14<% djula_endblock "d" %>15'
      source_template_name = '/aa/11.html.erb'
      
      source_template_key = '/aa/11.html'            
      
      assets = {
        base_template_name => base_src,
        source_template_name => source_src
      }
      
      should_output = '1810345127'
      
      f = Djula::TemplateFolder.new nil
      f.update_asset_hash assets
      x = f.get source_template_key
      x.render.must_equal should_output
    end

    it 'should work if the extended template is also extending another template' do 
      base_src_0 = '1<% djula_block "a" %>2<% djula_endblock "a" %>3<% djula_block "b" %>4<% djula_endblock "b" %>5<% djula_block "c" %>6<% djula_endblock "c" %>7'
      base_template_name_0 = '/aa/bb/cc/33.html.erb'
      
      base_src_1 = '8<% djula_extends "cc/33.html.erb" %>9<% djula_block "b" %>10<% djula_endblock "b" %>11<% djula_block "d" %>12<% djula_endblock "d" %>13'
      base_template_name_1 = '/aa/bb/22.html.erb'

      source_src = '14<% djula_extends "bb/22.html.erb" %>15<% djula_block "a" %>16<% djula_endblock "a" %>17<% djula_block "e" %>18<% djula_endblock "e" %>19'
      source_template_name = '/aa/11.html.erb'
      
      source_template_key = '/aa/11.html'
      
      assets = {
        base_template_name_0 => base_src_0,
        base_template_name_1 => base_src_1,
        source_template_name => source_src
      }
      
      should_output = '181416310567'
            
      f = Djula::TemplateFolder.new nil
      f.update_asset_hash assets
      x = f.get source_template_key
      x.render.must_equal should_output
    end
    
    it 'should be able to include other templates' do 
      
      include_src = '1'
      include_template_name = '/aa/include_me.html.erb'
      
      base_src = "2<%= djula_include \"#{include_template_name}\" %>3"
      base_template_name = '/aa/index.html.erb'
      base_template_key = '/aa/index.html'
        
      should_output = '213'
      
      assets = {
        include_template_name => include_src,
        base_template_name => base_src
      }
            
      f = Djula::TemplateFolder.new nil
      f.update_asset_hash assets
      x = f.get base_template_key
      x.render.must_equal should_output
    end
    
    it 'should be able to pass new variables to included templates' do 

      include_src = '1<%= @a %>2'
      include_template_name = '/aa/include_me.html.erb'
      
      base_src = "2<%= djula_include \"#{include_template_name}\", 'a' => '3' %>4"
      base_template_name = '/aa/index.html.erb'
      base_template_key = '/aa/index.html'
        
      should_output = '21324'
      
      assets = {
        include_template_name => include_src,
        base_template_name => base_src
      }
            
      f = Djula::TemplateFolder.new nil
      f.update_asset_hash assets
      x = f.get base_template_key
      x.render.must_equal should_output
    end
    
    it 'included templates should ONLY see the template variables that are explicitly passed to them' do 

      include_src = '1<%= @a.inspect %>2<%= @b.inspect %>3'
      include_template_name = '/aa/include_me.html.erb'
      
      base_src = "4<%= @a %>5<%= @b %>6<%= djula_include \"#{include_template_name}\", 'a' => '7' %>8"
      base_template_name = '/aa/index.html.erb'
      base_template_key = '/aa/index.html'
      
      should_output = '4951061"7"2nil38'
      
      assets = {
        include_template_name => include_src,
        base_template_name => base_src
      }
            
      f = Djula::TemplateFolder.new nil
      f.update_asset_hash assets
      x = f.get base_template_key
      x.render('a' => 9, 'b' => 10).must_equal should_output

    end
    
    
    # is this really necessary?
    it 'should find "/index.html.erb" when asked for "/"' do
      src = "1+1 = <%= 1 + 1 %>"
      template_name = '/index.html.erb'
      assets = {template_name => src}
      
      f = Djula::TemplateFolder.new nil
      f.update_asset_hash assets
      x = f.get "/"
      x.render.must_equal "1+1 = 2"
    end
    
    it 'should only execute djula_mockup_do code when in mockup mode' do
      src = '1<%= @x %>2<% @x = 3 %>4<%= @x %>5<% djula_mockup_do{ @x = 6 } %>7<%= @x %>8'
      src_template_name = '/aa/template.html.erb'
      src_template_key = '/aa/template.html'
      
      should_output = '134'
      
      assets = {
        src_template_name => src
      }
      
      should_output_in_mockup_mode = '192435768'
      f_mockup = Djula::TemplateFolder.new nil, :mockup_mode => true
      f_mockup.update_asset_hash assets
      x_mockup = f_mockup.get src_template_key
      x_mockup.render('x' => 9).must_equal should_output_in_mockup_mode
      
      should_output_in_not_mockup_mode = '192435738'
      f_not_mockup = Djula::TemplateFolder.new nil
      f_not_mockup.update_asset_hash assets
      x_not_mockup = f_not_mockup.get src_template_key
      x_not_mockup.render('x' => 9).must_equal should_output_in_not_mockup_mode      
    end
    
  end
  
  
end end