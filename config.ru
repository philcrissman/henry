
require 'toto'

# Rack config
use Rack::Static, :urls => ['/css', '/js', '/images', '/favicon.ico'], :root => 'public'
use Rack::CommonLogger

if ENV['RACK_ENV'] == 'development'
  use Rack::ShowExceptions
end

module Toto
  class Site
    def index type = :xml
      type = :xml # override!
      case type
        when :html
          # doesn't make sense, but it seemed to be working before...
          {:articles => self.articles.reverse.map do |article|
              Article.new article, @config
          end }.merge archives
        when :xml, :json
          return :articles => self.articles.reverse.map do |article|
            Article.new article, @config
          end
        else return {}
      end
    end
  
    def blog type = :html
      case type
        when :html
          {:articles => self.articles.reverse.map do |article|
              Article.new article, @config
          end }.merge archives
        when :xml, :json
          return :articles => self.articles.reverse.map do |article|
            Article.new article, @config
          end
        else return {}
      end
    end
    
    def feed type = :xml
      type = :xml # override! will this work?
      case type
        when :html
          {:articles => self.articles.reverse.map do |article|
            Article.new article, @config
          end }.merge archives # why?
        when :xml, :json
          return :articles => self.articles.reverse.map do |article|
            Article.new article, @config
          end
        else return {}
      end
    end
    
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
  
  class Article
    def path()    self[:date].strftime("/%Y/%m/%d/#{slug}") end
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
   set :author,    ENV['USER']                               # blog author
   set :title,     "philcrissman.com"                        # site title
   set :root,      "main"                                   # page to load on /
  # set :date,      lambda {|now| now.strftime("%d/%m/%Y") }  # date format for articles
  set :markdown,  :smart                                    # use markdown + smart-mode
  set :disqus,    "philcrissman"                                     # disqus id, or false
  # set :summary,   :max => 150, :delim => /~/                # length of article summary and delimiter
  # set :ext,       'txt'                                     # file extension for articles
  # set :cache,      28800                                    # cache duration, in seconds
  # set :cache,      0                                    # cache duration, in seconds
  set :url,       "philcrissman.com"

  set :date, lambda {|now| now.strftime("%B #{now.day.ordinal} %Y") }
end

run toto


