djula
=====

djula is a templating infrastructure. it's goals are to make it easy to:

* create interactive UI mockups
* integrate those UI mockups into real applications
* make sure that the codebase stays agile, even after integration with larger app

it's approach to accomplishing the above is to add the following to ERB:

* a webserver for viewing the mockups
* ability to specify example data & routes to use when viewing interactive mockups
* ability to run the same template code in mockups or production with no code change
* template inheritance (based on django templating language)

Todo:

* add support for haml & sass
* better compiler messages, sanity checking, etc

DOCUMENTATION
-------------------------

...to do...

...at the moment the best way to jump in is to check out the examples below:

RUNNING THE EXAMPLES AS INTERACTIVE MOCKUPS
-------------------------------------------

start the server, pointing it to the example folder:

    bundle exec rake djula:mockup_server TEMPLATE_FOLDER=examples/hello_world

(optional PORT argument defaults to 3001)

(substitute "examples/hello_world" with any example, eg "examples/example_data/simple")

then point the browser to the port you are running the server on: http://0.0.0.0:3001/

if for some reason you feel like starting it from within ruby:

    s = Djula::Server.new 'examples/hello_world', 
    s.start

FYI HOW TO INTEGRATE THE EXAMPLES INTO A RUBY APP
-------------------------------------------------

    f = Djula::TemplateFolder.new 'examples/hello_world'
    t = f.get "/"
    t.render

    # an example that requires arguments:
    f = Djula::TemplateFolder.new 'examples/example_data/simple'
    t = f.get "/"
    t.render :foo => 'WORLD', :bar => 2


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