project('com.github.manhelper', 'vala', 'c', version: '0.1.0')

cc = meson.get_compiler('c')
m_dep = cc.find_library('m', required : false)
gnome = import('gnome')

gresources = gnome.compile_resources(
    meson.project_name()+'_resources', 
    'ui/manhelper.gresource.xml',
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
    dependency('libgda-5.0'),
    dependency('libxml-2.0'),
    m_dep,
]

sources = files('src/Application.vala',
                'src/KeywordList.vala',
                'src/Bookmarks.vala',
                'src/MultiTabPager.vala',
                'src/PageZoomer.vala',
                'src/Preferences.vala',)

app = executable(meson.project_name(), 
                 sources,
                 gresources, 
                 dependencies: dependencies, 
                 install: true,)

meson.add_install_script('./postinstall.sh')