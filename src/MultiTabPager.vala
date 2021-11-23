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
    /* Add multitabs using scrolled window. */
    [GtkTemplate (ui = "/ui/multitab_pager.ui")]
    internal class MultitabPager: Gtk.Notebook
    {
        MainWin win;
        string page_no = "page no.";

        [GtkChild]
        internal unowned Gtk.ScrolledWindow first_scrolled;
        [GtkChild]
        internal unowned Gtk.Label first_label;
        [GtkChild]
        internal unowned Gtk.Button first_btn_close_page;
        [GtkChild]
        internal unowned Gtk.Image image_close;

        public int n_pages {get {return this.get_n_pages();}}

        public MultitabPager(MainWin win)
        {
            WebKit.WebView view; 
            this.win = win;
            win.pager = this;
            view = new WebKit.WebView();
            this.first_scrolled.add(view);
            win.view_current = view;

            view.set_data<Gtk.Button>("button",first_btn_close_page);
            first_btn_close_page.set_data<Gtk.Label>("label",first_label);
            first_scrolled.set_data<WebKit.WebView>("view",view);

            view.load_changed.connect(on_view_load_finished);
            view.button_press_event.connect(win.on_search_list_outside_mouse_press);
        }

        public void append_manpage()
        {
            var new_scrolled = new Gtk.ScrolledWindow(null,null);
            var label_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL,0);
            this.append_page(new_scrolled,label_box);

            var page_label = new Gtk.Label(page_label_text(this.n_pages));
            var btn_page_close = new Gtk.Button();
            btn_page_close.set_data<Gtk.Label>("label",page_label);
            var image_dup = new Gtk.Image();

            string icon_name;
            Gtk.IconSize icon_size;
            image_close.get_icon_name(out icon_name,out icon_size);
            image_dup.set_from_icon_name(icon_name,icon_size);
            btn_page_close.set_image(image_dup);
            
            btn_page_close.set_relief(Gtk.ReliefStyle.NONE);
            label_box.pack_start(page_label,false,true,0);
            label_box.pack_start(btn_page_close,false,true,0);
            btn_page_close.set_data<int>(page_no,this.n_pages);
            btn_page_close.clicked.connect(on_btn_page_close_clicked);
            
            var new_view = new WebKit.WebView(); 
            new_view.set_data<Gtk.Button>("button",btn_page_close);
            new_view.load_changed.connect(on_view_load_finished);
            new_view.button_press_event.connect(win.on_search_list_outside_mouse_press);
            //win.view += new_view; /* Dynamically increase the view array */
            //new_view.button_press_event.connect(on_view_mouse_press);
            //new_scrolled.add_with_properties(new_view);
            new_scrolled.add(new_view);
            new_scrolled.set_data<WebKit.WebView>("view",new_view);
            new_scrolled.set_data<Gtk.Button>("button",btn_page_close);

            new_scrolled.show_all();
            label_box.show_all();

            this.set_current_page(this.n_pages-1);
            /* Notify that we have switched page */
            this.switch_page(new_scrolled,this.n_pages-1); 

            /* Set page zoom ratio accordingly */
            double ratio;
            uint32 font_size_new;
            var settings = new_view.get_settings();
            var page_zoomer = this.win.page_zoomer;
            ratio  = int.parse(page_zoomer.entry_zoom.get_text())/100.0;
            font_size_new = (uint32)(Math.round(this.win.init_font_size*ratio));
            
            settings.set_default_font_size(font_size_new);
            new_view.set_settings(settings);
        }
        
        public void on_view_load_finished(WebKit.WebView self, WebKit.LoadEvent load_event)
        {
            if (load_event == WebKit.LoadEvent.FINISHED)
            {
                //print("Load finished!\n");
                
                Gtk.Button btn_page_close = self.get_data("button");
                Gtk.Label page_label = btn_page_close.get_data("label");

                var title_page = self.get_title().replace("Man page of ","");
                page_label.set_text(title_page);
            }
        }

        public void on_btn_page_close_clicked(Gtk.Button self)
        {
            var page_index = self.get_data<int>(page_no);

            /* Update page_no of each button after the closed page */ 
            for(var ii=page_index;ii<this.n_pages;ii++)
            {
                var page = this.get_nth_page(ii);
                Gtk.Button btn_close = page.get_data("button");
                btn_close.set_data<int>(page_no,ii); /* Decrease the page_no by 1 */
                Gtk.Label page_label = btn_close.get_data<Gtk.Label>("label");

                var label = page_label.get_text();
                var pattern = "^Page [0-9]+$";
                if (Regex.match_simple(pattern,label))
                {
                    page_label.set_text(page_label_text(ii));
                }
            }
            
            this.remove_page(page_index-1);
        }

        private string page_label_text(uint index)
        {
            return "Page "+index.to_string();
        }

        [GtkCallback]
        private void on_page_switched(Gtk.Widget page,uint page_num)
        {
            win.view_current = page.get_data<WebKit.WebView>("view");

            if (win.prefer_dialog!=null)
            {
                win.prefer_dialog.update_page_prefer();
                win.prefer_dialog.view = win.view_current;
            }
            win.page_zoomer.update_view_zoom();
            win.view_current.reload();
           //win.view_current.load_uri("https://developer.gnome.org/icon-naming-spec/");
        }
    }

}
