# jekyll-articled-webpush
Integrate the [Articled.io](https://articled.io/) widget with your Jekyll blog and start sending webpush notifications immediately!

## Installation
``` bash
$ gem install jekyll-articled-webpush
```

Add the plugin to your blog's Gemfile: 
``` bash
gem 'jekyll-articled-webpush'
```

## Options
_config.yml: 
``` yaml
articled:
  api_public_key: 
  app_public_key:
  
  #optional
  service_worker: <service worker filename> #Only use this you already have a service worker installed
```

## Guide
* Get your `API Public Key` and `App Public Key` in the [Articled.io dashboard](https://articled.io/dashboard).
* Edit your `_config.yml` to include Articled.io settings.
* Use `{% articled_widget %}` tag in `.md` files


## License
MIT
