require 'erb'
require 'yaml'

module Djula class Template
  
  def initialize(template_folder, src)
    @template_folder = template_folder
    @_erb_template = ERB.new src
  end
  
  def render(template_dictionary={})
    context = TemplateBindingContext.new template_dictionary, @template_folder
    @_erb_template.result context.get_binding
  end
  
  attr_accessor :template_folder, :_erb_template  

end end