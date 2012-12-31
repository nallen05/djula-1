djula
=====

djula is a templating infrastructure. it's goals are to make it easy to:

* create interactive UI mockups
* integrate code from the mockups into real applications
* make sure that this UI codebase stays agile, even after integration with larger app

it's approach to accomplishing the above is to add the following to ERB:

* a webserver for previewing projects as interactive mockups
* ability to specify example data & routes to use when previewing projects as interactive mockups
* ability to run the same template code in mockups or production with no code change
* template inheritance (based on django templating language)

Todo:

* add support for haml & sass
* better compiler messages, sanity checking, etc

DOCUMENTATION
-------------------------

A "djula project" consists of 2 folders:

* a template folder -- containing dynamic template files (ending in .erb), mockup data (djula_mockup_data.json), and mockup routes (djula_mockup_routes.json)
* a static folder -- containing the project's static content. for simple projects this may be the same folder as the template folder

To preview a project as an interactive mockup:

   template_folder = "examples/hello_world"
   static_folder = "examples/hello_world"
   port = 3001
   s = Djula::Server.new template_folder, :static_folder => static_folder, :port => port
   s.start # now point your browser to http://0.0.0.0:3001

To render templates (not interactive preview/mockup):

   f = Djula::TemplateFolder.new 'examples/hello_world'
   t = f.get "/"
   t.render

In order to pass variable values to the template, give them as opts to Djula::TemplateFolder#render

   f = Djula::TemplateFolder.new 'examples/example_data/simple'
   t = f.get "/"
   t.render :foo => 'WORLD', :bar => 2

...to do: document features...

* djula_extends / djula_block / djula_endblock
* djula_include
* djula_example_data.json
* djula_example_routes.json
* djula_mockup_do

...at the moment the best way to jump in is to check out the examples below:

PREVIEWING THE EXAMPLES AS INTERACTIVE MOCKUPS
----------------------------------------------

start the server, pointing it to the example you want to run:

    bundle exec rake djula:example TEMPLATE_FOLDER=examples/hello_world

(optional PORT argument defaults to 3001)

(substitute "examples/hello_world" with any example, eg "examples/example_data/simple")

EXAMPLES
--------

1. examples/hello_world

  very simple dynamic content example

2. examples/djula_example_data/simple

  demo showing display of "example" data pulled from dictionary "djula_example_data.json"

3. examples/djula_example_data/complex

  demo showing display of "example" data pulled from dictionary "djula_example_data.json".
  this one is more complex because it shows that "djula_example_data.json" values can be JSON data structures 
  like arrays and hashes that can be iterated-over with normal ruby iterators

4. examples/extends/simple

  simple demo showing that template "index.html.erb" extends "base.html.erb"

5. examples/extends/complex

  more convoluted inheritance example showing a template extending a template that it itself is extended.

7. examples/include/simple

  simple demo showing that you can include one template into another

8. examples/include/complex

  demo showing that included templates only see the variables that get passed to them

9. examples/routes/simple

   simple demo showing that example routes can be specified using a "djula_example_routes.json" file

10. examples/djula_mockup_do/setting_content_type

   simple demo showing that you can use djula_mockup_do to manually set the content type of a template