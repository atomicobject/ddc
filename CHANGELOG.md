# DDC Changelog

### 0.1.8

* ResponseBuilder#delete no longer requires arg

### 0.1.7

* patch to fix 0.1.6 bug

### 0.1.6

* remove use of `qualified_const_*` calls to fix a bug with global lookup
* add :parent option

### 0.1.5

* remove :render_opts to use :object_render_opts
* add :errors_render_opts

### 0.1.4

* remove :serializer and :each_serializer,  use :render_opts to pass a hash

### 0.1.2

* add :serializer and :each_serializer as action options

### 0.1.1

* Fix update status code
* Add missing delete for generated services

### 0.1.0

* API updates to be more consistent
* Add ServiceBuilder that delegats to AR Model or XxxxxFinder

### 0.0.1

* Initial release
