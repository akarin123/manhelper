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
        private Gdk.RGBA title_rgba;
        private Gdk.RGBA header_rgba;
        private Gdk.RGBA regular_rgba;
        private Gdk.RGBA bold_rgba;
        private Gdk.RGBA italic_rgba;

        private ThemeDialog theme_dialog;

        public ThemeCSS(ThemeDialog theme_dialog)
        {
            this.theme_dialog = theme_dialog;

            title_rgba = this.theme_dialog.btn_title.get_rgba();
            header_rgba = this.theme_dialog.btn_header.get_rgba();
            regular_rgba = this.theme_dialog.btn_regular.get_rgba();
            bold_rgba = this.theme_dialog.btn_bold.get_rgba();
            italic_rgba = this.theme_dialog.btn_italic.get_rgba();
        }

        private void set_theme_CSS()
        {
        }

        public string to_string()
        {
            // need further work
            StringBuilder str_builder;

            str_builder = new StringBuilder();

            str_builder.append("""<style type="text/css">"""+"\n");
            
            var title_cstr = title_rgba.to_string();
            var header_cstr = header_rgba.to_string();
            var regular_cstr = regular_rgba.to_string();
            var bold_cstr = bold_rgba.to_string();
            var italic_cstr = italic_rgba.to_string();

            str_builder.append(title_cstr+"\n");
            str_builder.append(header_cstr+"\n");
            str_builder.append(regular_cstr+"\n");
            str_builder.append(bold_cstr+"\n");
            str_builder.append(italic_cstr+"\n");

            str_builder.append("""</style>"""+"\n");
            //print("%s\n%s\n%s\n%s\n%s\n",title_cstr,header_cstr,regular_cstr,bold_cstr,italic_cstr);

            return str_builder.str;
        }
    }
}