
require 'erb'
require 'json'

## todo:
# --more meaningful error messages
# --only compile files affected by recent changes
# --I18n (what strategy?)
# --logging?
# --ghetto lint (regexp search for "@var"...)
# --haml & sass

module Djula class TemplateFolder

  # api

  def initialize(template_directory, opts={})
    puts "Djula::TemplateFolder.new #{template_directory.inspect}, #{opts.inspect}"
    
    @mockup_mode = opts[:mockup_mode]
    
    @recognize_template_suffix = (opts[:recognize_template_suffix] or ".erb")
    @ignore_file_patterns = (opts[:ignore_file_patterns] or ["^\\.","^_"])    

    @template_directory = File.expand_path(template_directory,Dir::pwd) if template_directory # could be NIL if asset_hash provided (eg test scenario)

    @asset_hash = nil
    @compiled_templates = nil
    @mockup_server = opts[:mockup_server]
  end  
  
  def update_asset_hash(merge_in={})
    @asset_hash = get_fresh_asset_hash.merge merge_in
  end

  def compile_templates(assets=@asset_hash, compiled={})
    assets.each{|tn,src| compiled[tn] = Template.new(self,tn,self.precompile_standalone_src(tn,assets)) }
    @compiled_templates = compiled
  end
  
  def get(path_without_template_suffix)
    
    # if the asset hash still needs to be set or the templates still need to be compiled then do that as part of the first request
    self.update_asset_hash unless @asset_hash
    self.compile_templates unless @compiled_templates
    
    path_without_template_suffix = "/" unless (path_without_template_suffix and (path_without_template_suffix.length > 0))
    template_path = (path_without_template_suffix == "/") ? "/index.html" : path_without_template_suffix
    template_path = template_path + @recognize_template_suffix
    @compiled_templates[template_path]
  end
   
  # private
  
  attr_accessor :template_directory, :mockup_mode, :recognize_template_suffix, :ignore_file_patterns, :asset_hash, :compiled_templates, :mockup_server
  
  # dealing with files
  
  def get_fresh_asset_hash(directory_path=@template_directory)    

    return {} unless directory_path
    
    length_of_directory_path = directory_path.length

    files = Dir.glob(directory_path + "/**/*")
    files = files.select{|pn| self.looks_like_template_file? pn}
    files = files.reject{|pn| self.should_ignore_filename? pn}
    files = files.reject{|pn| File.directory? pn }
  
    h = {}

    files.each do |pn|
      tn = pn[length_of_directory_path..-1]
      puts "#{tn.inspect} <- #{pn.inspect}"
      h[tn] = File.read pn
    end
    h
  end
  
  def looks_like_template_file?(filename)
    filename[(@recognize_template_suffix.length * -1)..-1] == @recognize_template_suffix ? filename : false
  end

  def should_ignore_filename?(filename)
    @ignore_file_patterns.each{|pttrn| (return filename) if File.basename(filename).match(pttrn)}
    return false
  end
  
  # compiling the templates ("djula_extends" & "djula_block"/"djula_endblock")
  
  def precompile_standalone_src(template_name,assets=@asset_hash)
    puts "Compiling template: #{template_name}"
    template_stack = self.get_template_stack template_name
    current_template_name = template_stack[0]
    ret = assets[current_template_name]
    template_stack[1..-1].each do |extend_by_template_name|
     puts "Compiling template: #{template_name} -- extending template #{extend_by_template_name.inspect}"
     ret = TemplateFolder.rewrite_extending_template(assets[extend_by_template_name],ret)
     current_template_name = extend_by_template_name
    end
    ret
  end
  
  def get_template_stack(template_name,assets=@asset_hash)
    template_stack = [template_name]
    current = template_name
    while (extends = TemplateFolder.template_extends?(assets[current],current))
      template_stack << extends
      current = extends
    end
    template_stack.reverse
 end
  
  def self.template_extends?(template_src,template_name)
    if ex = /<% djula_extends(.*?)%>/i.match(template_src)
      return TemplateFolder.absolutize_template_path eval(ex[1],binding).to_s, template_name
    end
    return nil    
  end
  
  def self.absolutize_template_path(target_template,reffering_template)    
    File.expand_path target_template, File.dirname(reffering_template)
  end
  
  def self.rewrite_extending_template(source_src,base_template_src)
    ret = base_template_src
    TemplateFolder.get_template_blocks_list(base_template_src).each do |block_name|
      ret = TemplateFolder.maybe_replace_block ret, source_src, block_name
    end
    return self.insert_before_first_block_form(TemplateFolder.get_src_before_extends_form(source_src),ret)
#    return (TemplateFolder.get_src_before_extends_form(source_src) + ret)
  end
  
  def self.get_template_blocks_list(template_src)
    template_src.scan(/<% djula_block(.*?)%>/i).map{|ex| eval(ex[0],binding) }
  end 

  def self.maybe_replace_block(to_template_src,from_template_src,block_name)
    maybe_replace = TemplateFolder.extract_block_form to_template_src, block_name
    if (new_version = TemplateFolder.extract_block_form from_template_src, block_name)
#      puts "Compiling template: #{} -- rewwriting template #{} block #{block_name.inspect} using m #{}"           
      to_template_src.gsub maybe_replace, new_version
    else
      to_template_src
    end
  end
  
  def self.extract_block_form(template_src,block_name)
    start_match = TemplateFolder._get_tag_src_string template_src, "djula_block", block_name
    end_match   = TemplateFolder._get_tag_src_string template_src, "djula_endblock", block_name
    if (start_match)
      raise "can't find the 'djula_endblock' for #{block_name.inspect}..." unless end_match
      template_src[template_src.index(start_match)...(template_src.index(end_match)+end_match.length)]
    else
      nil
    end
  end

  def self._get_tag_src_string(template_src,tag_name,block_name)
    template_src.scan(/(<% #{tag_name}(.*?)%>)/i).each do |x|
      whole_match, unevaluated_block_name = x
      found_block_name = eval(unevaluated_block_name,binding).to_s
      if (found_block_name == block_name)
        return whole_match
      end
    end
    return nil
  end
  
  def self.get_src_before_extends_form(src)
    i = src.index('<% djula_extends')
    src[0...(i or -1)]
  end
  
  def self.insert_before_first_block_form(insrt,src)
    i = src.index('<% djula_block')
    src[0...i] + insrt + src[i..-1]
  end

end end
