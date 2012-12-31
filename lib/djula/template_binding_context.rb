
module Djula class TemplateBindingContext
  def initialize(bindings_hash,compiled_template_folder)
    bindings_hash.each_pair do |k, v|
      instance_variable_set('@' + k.to_s, v)
    end
    @_compiled_template_folder = compiled_template_folder
  end
  
  def get_binding
    binding
  end
  
  private # default bindings
  
  def djula_block(name)
    puts "entering block: #{name.inspect}"
  end
   
  def djula_endblock(name)
    puts "leaving block: #{name.inspect}"
  end
  
  def djula_extends(template_name)
    # maybe we want to leave this to print useful debug output?
    raise "'djula_extends' should never be called, it should be factored out by the Djula compiler!!"
  end
  
  def djula_include(template_name,bindings_hash={})
    # maybe we want to leave this to print useful debug output?
    template_key = template_name[0...(0-".erb".length)] # ...hacky...
    @_compiled_template_folder.get(template_key).render bindings_hash
  end
  
  def djula_mockup_do
    yield if @_compiled_template_folder.mockup_mode
  end
  
  def mockup_server
    @_compiled_template_folder.mockup_server
  end
  
end end