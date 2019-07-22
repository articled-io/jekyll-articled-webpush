require 'net/http'
require 'uri'
require "json"
require "jekyll"

class ArticledWidget < Liquid::Tag

  def initialize(tagName, content, tokens)
    super
    @content = content
  end



  def render(context)

    articled_config = context.registers[:site].config["articled"] || false

    #checking _config.yml
    if !articled_config
      raise "jekyll-articled-webpush: Missing configuration!"
    end

    if !articled_config.key?("api_public_key")
      raise "jekyll-articled-webpush: Mising API Public Key In _config.yml"
    end

    if !articled_config.key?("app_public_key")
      raise "jekyll-articled-webpush: Mising APP Public Key In _config.yml"
    end

    if articled_config.key?("service_worker")
      if articled_config["service_worker"] != "service-worker.js"
        raise "jekyll-articled-webpush: Can not use '" +  articled_config["service_worker"] + "' as a service worker. Please rename your service worker to 'service-worker.js'"
      end
    end


    #read articled settings
    articled_file = File.join(File.dirname(__FILE__), "articled.json")
    articled_json = File.read(articled_file)
    articled      = JSON.parse(articled_json)
    
    if articled["running"]

      userDir = articled["userDir"]
      appName = articled["appName"]



      #widget script
      %Q{#{widget_articled(userDir, appName)}}
      
    else

      #setup service worker
      sw_file = context.registers[:site].in_source_dir("service-worker.js")

      if articled_config.key?("service_worker")
        if !File.exist?(context.registers[:site].in_source_dir("articled-worker.js"))
          aw_file = context.registers[:site].in_source_dir("articled-worker.js")
          File.write(aw_file, sw_articled)
          File.write(sw_file, " importScripts(\"articled-worker.js\");", mode: "a")
        end
      else
        File.write(sw_file, sw_articled)
      end
      


      userDir = ""
      appName = ""

      #get user dir
      articled_server = Net::HTTP.post_form( URI.parse("https://articled.io/api/user/public"), [["apiPublicKey", articled_config["api_public_key"]]] )
      user_dir_data   = JSON.parse(articled_server.body)
      
      if user_dir_data["status"]
        userDir = user_dir_data["userDir"]
      else
        raise "jekyll-articled-webpush: Invalid Public API Key"
      end
      


      #get app name
      articled_server = Net::HTTP.post_form( URI.parse("https://webpush.articled.io/api/app/public"), [["apiPublicKey", articled_config["api_public_key"]]] )
      apps_data       = JSON.parse(articled_server.body)

      apps = apps_data["apps"]
      for app in apps do
          if app["appPublicKey"] == articled_config["app_public_key"]
              appName = app["name"]
          end
      end

      if appName.length == 0
        raise "jekyll-articled-webpush: Could not find any apps matching the provided Public APP Key"
      end



      #save json
      new_json = { "running": true, "userDir": userDir, "appName": appName }
      File.write(File.join(File.dirname(__FILE__), "articled.json"), JSON.generate(new_json))
      


      #widget script
      %Q{#{widget_articled(userDir, appName)}}

    end

  end


  
  #service worker string
  def sw_articled
    return "self.addEventListener(\"push\",function(event){var data={};if(event.data){data=event.data.json();} var title=data.title||\"Untitled\";var message=data.message||\"Empty\";var tag=data.tag||null;var icon=data.icon||null;var url=data.url;var image=data.image;event.waitUntil(self.registration.showNotification(title,{body:message,tag:tag,icon:icon,image:image,data:url}));});self.addEventListener(\"notificationclick\",function(event){var url=event.notification.data;if(url){clients.openWindow(url);}else{return;}});self.addEventListener(\"activate\",function(event){event.waitUntil(self.clients.claim());});"
  end



  #widget script
  def widget_articled(userDir, appName)
    return "<script>\n" + 
            "(function(a,r,t,i,c,l) {\n" + 
            "i=r.getElementsByTagName(\"head\")[0],\n" +
            "c=r.createElement(\"script\"), \n" +
            "l=r.createElement(\"link\");" +
            "c.type=\"text/javascript\";c.src=t+a+\".js\";\n" + 
            "l.type=\"text/css\";l.rel=\"stylesheet\";\n" + 
            "l.href=t+a+\".css\";i.appendChild(l);\n" + 
            "i.appendChild(c);\n" + 
            "})(\"articled\",document,\"https://articled.io/widget/" + userDir + "/" + appName + "/\");\n" + 
            "</script>" 
  end 




  Liquid::Template.register_tag "articled_widget", self
end