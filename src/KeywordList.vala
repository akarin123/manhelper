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
    /* Search list of man pages from entry text*/
    [GtkTemplate (ui = "/ui/keyword_list.ui")]
    private class KeywordList: Gtk.Window
    {
        public string keyword {get;set;default="";}
        public int find_num  {get;set;default=0;}
        private MainWin win;
        //private int x_list;
        //private int y_list;
        private Gtk.MenuItem last_selected = null;

        [GtkChild]
        private unowned Gtk.ScrolledWindow keywordscrolled;

        [GtkChild]
        internal unowned Gtk.MenuBar keywordmenu;
        //private Gtk.Box keywordbox;
        private string man_stdout;
        private string man_stderr;
        private int man_status;
        private string[] man_entries;
        private int max_show = 15;
        private int min_show = 5;
        //private Gtk.MenuItem menu_item;
        private int menu_item_height = -1;


        public KeywordList (MainWin win, string keyword)
        {
            this.win = win;
            this.keyword = keyword.replace("\\","");  /* Avoid syntax error for man -k <keyword> */
            
            /* Find section number, 0 is "All Sections" */
            var section_num = this.win.section_list.section_combo.get_active();

            try 
            {
                if (section_num >= 1)
                {
                    Process.spawn_command_line_sync (@"man -k -s $(section_num) "+"\""+this.keyword+"\"",out man_stdout,out man_stderr,out man_status);
                } 
                else
                {
                    Process.spawn_command_line_sync ("man -k "+"\""+this.keyword+"\"",out man_stdout,out man_stderr,out man_status);
                }
            } 
            catch (SpawnError e) 
            {
                message(e.message);
            }
            man_entries = man_stdout.split("\n");

            if (man_entries.length>0)
            {
                find_num = man_entries.length-1; /* string.split() will add an extra "\n" string at the end */
                man_entries=man_entries[0:find_num];
            }
            
            for (var index=0;index<find_num;index++)
            {
                var menu_item = new Gtk.MenuItem.with_label(man_entries[index]); 
                menu_item.activate.connect(navigate_to_uri);
                this.keywordmenu.append(menu_item);
                
            }

            if (menu_item_height < 0)
            {
                var win_tmp = new Gtk.Window();
                var menu_item_tmp = new Gtk.MenuItem.with_label("temp menu item"); 
                win_tmp.add(menu_item_tmp);
                win_tmp.show_all();
                menu_item_height = menu_item_tmp.get_allocated_height(); 
                win_tmp.destroy();
            }

            if (find_num<min_show)
            {
                keywordscrolled.propagate_natural_height=true;
            }
            else
            {
                this.height_request = menu_item_height * int.min(find_num,max_show);
            }
            
            this.set_attached_to(win);
            this.width_request = win.entry_search.get_allocated_width();

            update_keyword_list_pos(win);

            Timeout.add(150,()=>{update_keyword_list_geom(this.win);return Source.CONTINUE;});

            this.set_transient_for(win);
        }

        internal void update_keyword_list_pos (MainWin win)
        {
            Gtk.Allocation entry_allcation;
            Gdk.Window search_list_gdkwin;

            if (this.get_realized())
            {
                win.entry_search.get_allocation(out entry_allcation);
                search_list_gdkwin = this.get_window();
                search_list_gdkwin.move_to_rect(entry_allcation,Gdk.Gravity.SOUTH_WEST,Gdk.Gravity.NORTH_WEST,Gdk.AnchorHints.RESIZE_Y,0,0);  
            }

        }

        internal void update_keyword_list_geom(MainWin win)
        {
            int width_new;
            Gtk.MenuItem selected_item = null;

            if (this.get_realized())
            {
                update_keyword_list_pos(win);
            }
            
            width_new = win.entry_search.get_allocated_width();

            if ((this.visible)&&(width_new-this.width_request).abs()>1)
            {
                this.width_request=width_new;
                this.resize(this.width_request,this.height_request);
                //print(@"width now:$(width_new),$(this.width_request), time:"+Time.local(time_t()).to_string()+"\n");
            }
            
            
            if (this.get_realized())
            {
                selected_item = this.keywordmenu.get_selected_item() as Gtk.MenuItem;
                this.last_selected = selected_item;
                //print(selected_item.label+"\n");
            }

            //return true;
        }

        [GtkCallback]
        private bool key_up_and_down (Gtk.Widget self,Gdk.Event evnt)
        {
            Gdk.EventKey key_evnt;
            uint keyval;

            key_evnt = evnt.key;
            keyval = key_evnt.keyval;
            
            if ((keyval == Gdk.Key.Up)||(keyval == Gdk.Key.Down))
            {
                int item_x,item_y;
                Gtk.Adjustment vadj;
                Gtk.MenuItem selected_item;
                int vadj_step = menu_item_height*max_show/3;
                if (this.get_realized())
                {
                    selected_item = this.keywordmenu.get_selected_item() as Gtk.MenuItem;
                
                    if (selected_item!=null)
                    {
                        selected_item.translate_coordinates(this,0,0,out item_x,out item_y);
            
                        if (item_y>this.height_request)
                        {
                            vadj = this.keywordscrolled.get_vadjustment();
                            while (item_y>this.height_request)
                            {
                                vadj.value = vadj.value+vadj_step;
                                selected_item.translate_coordinates(this,0,0,out item_x,out item_y);
                            }
                            //vadj.value +=item_y;
                            this.keywordmenu.select_item(selected_item);
                            //this.show();
                        }
                        else if(item_y<0)
                        {
                            vadj = this.keywordscrolled.get_vadjustment();
                            while (item_y<0)
                            {
                                vadj.value = vadj.value-vadj_step;
                                selected_item.translate_coordinates(this,0,0,out item_x,out item_y);
                            }
                            this.keywordmenu.select_item(selected_item);
                            //this.show();
                        }
                    }
                }

                /* need to turn off the mouse event,
                   but I haven't found a proper way */
                // future work here
            }

            return false;
        }
        [GtkCallback]
        private bool escape_key_destroy (Gtk.Widget self,Gdk.Event evnt)
        {
            Gdk.EventKey key_evnt;
            uint keyval;

            key_evnt = evnt.key;
            keyval = key_evnt.keyval;
            
            if (keyval == Gdk.Key.Escape)
            {
                this.destroy();
            }

            return false;
        }

        [GtkCallback]
        private bool mouse_leave_keyword_list (Gtk.Widget self,Gdk.Event evnt)
        {
            Gdk.EventCrossing evnt_cross;
            
            evnt_cross = evnt.crossing;
            var x = evnt_cross.x;

            if ((last_selected!=null)&&((x<=0)||(x>=this.get_allocated_width())))
            {   
                this.keywordmenu.select_item(last_selected);
            }

            return false;
        }
        
        private void navigate_to_uri (Gtk.MenuItem self)
        {
            //Gtk.MenuItem selected_item;
            string man_entry;
            string[] man_data;
            string sec_index="";
            string item_uri="";
            //selected_item = this.keywordmenu.get_selected_item() as Gtk.MenuItem; 

            man_entry = self.get_label();
            man_data= man_entry.split(" ");

            sec_index=man_data[1].replace("(","").replace(")","");
            //print(man_data[0]+"."+sec_index+"\n");
            item_uri="http://localhost/cgi-bin/man/man2html?"+sec_index+"+"+man_data[0].strip();
            this.win.view_current.load_uri(item_uri);

            /* Setup the CSS theme */
            if ((this.win.prefer_dialog == null) || (!this.win.prefer_dialog.get_realized()))
            {
                this.win.prefer_dialog = new PreferDialog(this.win);
            }

            this.win.prefer_dialog.view = this.win.view_current;
            this.win.prefer_dialog.hide();
            /* Add a 50 ms delay */
            Timeout.add(50,()=>{this.win.prefer_dialog.update_page_prefer();return Source.REMOVE;});

            this.win.last_entry_text = this.keyword; /* Update last entry text */

            this.destroy();
        }
        /*
        [GtkCallback]
        private bool search_list_follow(Gtk.Widget self, Gdk.EventConfigure evnt)
        {
            print("get reconfigure signal!"+Time.local(time_t()).to_string()+"\n");

            return true;
        }*/
    }
}
