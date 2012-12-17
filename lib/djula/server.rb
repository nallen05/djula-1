require 'webrick'

# todo:
# --pattern matching in mockup routes?
# --thing to stop browsers from caching?
# --https for secure demos?

module Djula class Server
  include WEBrick
  
  def initialize(template_folder=nil,opts={})
    @template_folder = (template_folder or Dir::pwd)
    
    @port = opts.fetch :port, 3001
    @static_folder =  opts.fetch :static_folder, @template_folder

    @example_data_file_name = opts.fetch :example_data_file_name, "djula_example_data.json"
    @example_routes_file_name = "/djula_example_routes.json"
    
    @project_summary_page_template_key = File.dirname(File.expand_path(__FILE__)) + "/templates/generate_djula_project_summary_page.html"
    @project_summary_page_template_pathname = @project_summary_page_template_key + ".erb"
    
    @compiled_template_folder = nil
    @webrick_server = nil    
  end
  
  def start
    self.compile_templates

    puts "Starting server: http://#{Socket.gethostname}:#{port}"
    @webrick_server = HTTPServer.new :Port => @port, :DocumentRoot => @static_dir

    # trap signals to invoke the shutdown procedure cleanly
    ['INT', 'TERM'].each { |signal|
       trap(signal){ @webrick_server.shutdown} 
    }

    @webrick_server.mount_proc('/') {|req, resp|
      self.compile_templates
      
      # project summary page
      if (req.path == "/")
        template_vars = {
          'routes' => self.get_routes_from_file_system,
          'template_folder' => @template_folder,
          'templates_files' => (@compiled_template_folder.asset_hash.keys - [@project_summary_page_template_pathname]).sort,
          'static_folder' => @static_folder,
          'static_files' => Dir.glob("#{@static_folder}/**/*").map{|pn| pn[@static_folder.length..-1]}.sort
        }
        resp.body = @compiled_template_folder.get(@project_summary_page_template_key).render template_vars
        resp['Content-Type'] = WEBrick::HTTPUtils.mime_type( @project_summary_page_template_key, WEBrick::HTTPUtils::DefaultMimeTypes)       
      
      # dynamic template
      elsif (@template = @compiled_template_folder.get(req.path))
        resp.body = @template.render self.get_example_data_from_file_system(req.path)
        resp['Content-Type'] = WEBrick::HTTPUtils.mime_type @project_summary_page_template_key, WEBrick::HTTPUtils::DefaultMimeTypes

      # static content
      elsif (pn = @static_folder + "/"  + req.path ; File.exists?(pn))
         resp.body = File.read pn
         
      # matches a route defined in djula_example_routes.json
      elsif (pn = self.match_route?(req.path))
        @template = @compiled_template_folder.get pn
        resp.body = @template.render self.get_example_data_from_file_system(pn)

      # oops
      else
        resp.status = 404
        resp.body = "cant find template #{req.path.inspect}.erb or static file #{req.path.inspect}"
      end
    }
    
    @webrick_server.start
  end
  
  def compile_templates
    @compiled_template_folder = TemplateFolder.new @template_folder
    @compiled_template_folder.update_asset_hash(@project_summary_page_template_pathname => File.read(@project_summary_page_template_pathname))
    @compiled_template_folder.compile_templates
  end
  
  def get_example_data_from_file_system(file_key)    

    example_data = {}

    file_path = @template_folder + file_key
    file_subfolder_names = file_key.split("/").reject{|x| x.length == 0}[0...-1]
  
    look_in_folder = @template_folder
    ([""] + file_subfolder_names).each do |subfolder|
      look_in_folder = look_in_folder + "/" + subfolder
      maybe_example_data_file = look_in_folder + "/" + @example_data_file_name
      if File.exists?(maybe_example_data_file)
        src = File.read maybe_example_data_file
        (example_data = example_data.merge(JSON.parse(src))) if (src and (src.length > 0))
      end
    end 
    return example_data    
  end
  
  def match_route?(req_path) 
   puts "TODO: IMPLEMENT ROUTES PATTERN MATCHING"
   self.get_routes_from_file_system[req_path]
  end
  
  def get_routes_from_file_system
    
    routes = {}
    
    maybe_routes_path = @template_folder + @example_routes_file_name
    if File.exists?(maybe_routes_path)
      src = File.read maybe_routes_path
      (routes = JSON.parse(src)) if (src and (src.length > 0))
    end
    
    routes
  end

  # private

  attr_accessor :port, :webrick_server, :template_folder, :compiled_template_folder, :static_folder
  
end end