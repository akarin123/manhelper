project('manhelper', 'vala', 'c', version: '0.02')

#cc = meson.get_compiler('c')
#m_dep = cc.find_library('m', required : false)
gnome = import('gnome')

gresources = gnome.compile_resources(
    meson.project_name()+'_resources', 'ui/manhelper.gresource.xml',
    c_name: 'resources',
    source_dir:['ui']
)

dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gtk+-3.0'),
    dependency('gmodule-2.0'),
    dependency('webkit2gtk-4.0'),
    dependency('libsoup-2.4'),
    #m_dep,
]

sources = files('Application.vala','KeywordList.vala','Bookmark.vala')
executable(meson.project_name(), sources, gresources, dependencies: dependencies)
