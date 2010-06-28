
require 'toto'
require 'haml'

# Rack config
use Rack::Static, :urls => ['/css', '/js', '/images', '/favicon.ico'], :root => 'public'
use Rack::CommonLogger

if ENV['RACK_ENV'] == 'development'
  use Rack::ShowExceptions
end

module Toto
  class Site
  
    # Note: this method is identical to the original method found in Toto, except for the :404 line at the end; hacked to get a 404 page to work.
    # Put your 404 page in /templates/pages/404.rhtml
    def go route, type = :html
      route << self./ if route.empty?
      type, path = type =~ /html|xml|json/ ? type.to_sym : :html, route.join('/')
      context = lambda do |data, page|
        Context.new(data, @config, path).render(page, type)
      end
      
      body, status = if Context.new.respond_to?(:"to_#{type}")
        if route.first =~ /\d{4}/
          case route.size
            when 1..3
              context[archives(route * '-'), :archives]
            when 4
              context[article(route), :article]
            else http 400
          end
        elsif respond_to?(path)
          context[send(path, type), path.to_sym]
        elsif (repo = @config[:github][:repos].grep(/#{path}/).first) &&
              !@config[:github][:user].empty?
          context[Repo.new(repo, @config), :repo]
        else
          context[{}, path.to_sym]
        end
      else
        http 400
      end

    rescue Errno::ENOENT => e
      return :body => context[{}, :"404"], :type => :html, :status => 404
    else
      return :body => body || "", :type => type, :status => status || 200
    end
  end

  # convenience methods. Useful in blog templates.
  class Article  
    def month
      self[:date].strftime("%b")
    end
    
    def day
      self[:date].strftime("%d")
    end
    
    def year
      self[:date].strftime("%Y")
    end
  end
  
  class Server
    
  end
end

#


#
# Create and configure a toto instance
#
toto = Toto::Server.new do
  #
  # Add your settings here
  # set [:setting], [value]
  # 
  # set :author,    ENV['USER']                               # blog author
  # set :title,     Dir.pwd.split('/').last                   # site title; just override if you want to set the title explicitly
  # set :root,      "index"                                   # page to load on /
  # set :date,    lambda {|now| now.strftime("%d/%m/%Y") }  # date format for articles
  # set :markdown,  :smart                                    # use markdown + smart-mode
  # set :disqus,    false                                     # disqus id, or false
  # set :summary,   :max => 150, :delim => /~/                # length of article summary and delimiter
  # set :ext,       'txt'                                     # file extension for articles
  # set :cache,      28800                                    # cache duration, in seconds
  # set :cache,      0                                        # cache duration, in seconds
  # set :url,       "yourdomain.com"                          # if you need to
  
  set :format do
    Haml::Template.options[:format] = :html5
  end
  
  set :to_html   do |path, page, ctx|
    Haml::Engine.new(File.read("#{path}/#{page}.haml"), :format => :html5, :ugly => true).render(ctx)
  end

  set :error do |code|
    # fake the bindings for the layout haml
    class LayoutCtx
      def title; 'title' end
      def archives; "" end
    end

    Haml::Engine.new(File.read("templates/layout.haml")).render(LayoutCtx.new) do |content|
      Haml::Engine.new(File.read("templates/pages/error.haml")).render(Object.new,:code => code)
    end
  end
  
  set :date, lambda {|now| now.strftime("%B #{now.day} %Y") }
end

run toto


