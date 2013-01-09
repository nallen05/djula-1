require 'erb'

module Djula class Template
  
  def initialize(template_folder, template_name, src)
    @template_folder = template_folder
    @template_name = template_name
    @_erb_template = ERB.new src
  end
  
  def render(template_dictionary={})
    context = TemplateBindingContext.new template_dictionary, @template_folder
    @_erb_template.result context.get_binding
  end
  
  attr_accessor :template_folder, :template_name, :_erb_template

end end