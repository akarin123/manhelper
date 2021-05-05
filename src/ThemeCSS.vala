/*
* Copyright (c) 2021 XX Wu
*
* This file is part of Man Helper
*
* Man Helper is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
* Man Helper is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
* GNU General Public License for more details.
* You should have received a copy of the GNU General Public License
* along with Man Helper. If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: XX Wu <xwuanhkust@gmail.com>
*/

namespace ManHelper
{
    internal class ThemeCSS:Object
    {
        public Gdk.RGBA title_rgba = {};
        public Gdk.RGBA heading_rgba = {};
        public Gdk.RGBA regular_rgba = {};
        public Gdk.RGBA bold_rgba = {};
        public Gdk.RGBA italic_rgba = {};

        private ThemeDialog theme_dialog = null;
        internal PreferDialog prefer_dialog = null;

        public ThemeCSS()
        {
            var black = "rgb(0,0,0)";
            
            title_rgba.parse(black);
            heading_rgba.parse(black);
            regular_rgba.parse(black);
            bold_rgba.parse(black);
            italic_rgba.parse(black);
        }

        public ThemeCSS.from_theme(ThemeDialog theme_dialog)
        {
            this.theme_dialog = theme_dialog;

            title_rgba = this.theme_dialog.btn_title.get_rgba();
            heading_rgba = this.theme_dialog.btn_heading.get_rgba();
            regular_rgba = this.theme_dialog.btn_regular.get_rgba();
            bold_rgba = this.theme_dialog.btn_bold.get_rgba();
            italic_rgba = this.theme_dialog.btn_italic.get_rgba();
        }

        public void set_theme_CSS()
        {
            // need further work using Javascript
            //print("java script here!");
            WebKit.WebView view = null;
            if (this.theme_dialog!=null)
            {
                view = this.theme_dialog.view;
            }
            else if (this.prefer_dialog!=null)
            {
                //print("prefer!\n");
                view = this.prefer_dialog.view;
            }
            else
            {
                return;
            }

            var css_str = this.to_string();
            var java_script = @"var style = document.createElement('style'); style.innerHTML = '$(css_str)';document.head.appendChild(style)"; 
            
            /*
            try 
            {
                print(java_script);
                yield view.run_javascript(java_script);
            } 
            catch (Error e) 
            {
                message(e.message);

                print("fail\n");
            }*/
            
            // need further work here
            view.run_javascript.begin(java_script);
        }

        public string to_string()
        {
            // need further work
            StringBuilder str_builder;
            str_builder = new StringBuilder();

            var title_cstr = title_rgba.to_string();
            var heading_cstr = heading_rgba.to_string();
            var regular_cstr = regular_rgba.to_string();
            var bold_cstr = bold_rgba.to_string();
            var italic_cstr = italic_rgba.to_string();            

            //str_builder.append("""<style type="text/css">"""+" ");
            str_builder.append("h1 {color:"+title_cstr+"}"+" ");
            str_builder.append("h2 {color:"+heading_cstr+"}"+" ");
            str_builder.append("body {color:"+regular_cstr+"}"+" ");
            str_builder.append("b {color:"+bold_cstr+"}"+" ");
            str_builder.append("i {color:"+italic_cstr+"}"+" ");

            //str_builder.append("""</style>"""+" ");
            //print("%s\n%s\n%s\n%s\n%s\n",title_cstr,heading_cstr,regular_cstr,bold_cstr,italic_cstr);

            return str_builder.str;
        }
    }
}