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
    /* Main application. */
    public class App: Gtk.Application 
    {
        public uint section_num_max {get;default=9;}
        public MainWin win;

        internal string startup_filename {set;get;default="startup.js";}

        internal string bookmarks_parent_dir {set;get;default=".";}
        internal string bookmarks_directory {set;get;default="/.manhelper";}
        internal string bookmarks_filename {set;get;default="bookmarks";}
        internal DataBase bookmarks_db = null;
        private Gdk.Pixbuf app_icon;

        protected override void startup() 
        {
            base.startup();
            DataBase.init_database_directory(this);
        }

        protected override void activate()
        {             
            var app_win = new MainWin(this);

            app_win.show_all();

            this.win = app_win;

            try
            {
                app_icon = new Gdk.Pixbuf.from_resource("/ui/icon_manhelper.png");
                app_icon = app_icon.scale_simple(128,128,Gdk.InterpType.TILES);
                app_win.icon = app_icon;                
            }
            catch (Error e)
            {
                message(e.message);
            }
        }

    }

    /* This is the About dialog. */
    [GtkTemplate (ui = "/ui/about_dialog.ui")]
    public class AboutDialog: Gtk.AboutDialog
    {
        internal AboutDialog ()
        {
            Gdk.Pixbuf dialog_pixbuf;

            try 
            {
                dialog_pixbuf = new Gdk.Pixbuf.from_resource("/ui/icon_manhelper.png");
                dialog_pixbuf = dialog_pixbuf.scale_simple(128,128,Gdk.InterpType.TILES);
                this.logo=dialog_pixbuf;
            } 
            catch (Error e) 
            {
                //print("Unable to load the logo\n");
                message(e.message+"\n");
            }           
        }
    }

}

public static int main (string[] args)
{   
    var app = new ManHelper.App();

    return app.run(args);
}