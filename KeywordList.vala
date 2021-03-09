/*-
 * Authored by: XX Wu <xwuanhkust@gmail.com>
 */

namespace ManHelper
{   
    /*Add search list for man pages*/
    [GtkTemplate (ui = "/ui/keyword_list.ui")]
    private class KeywordList:Gtk.Window
    {
        public string keyword {get;set;default="";}
        public int find_num  {get;set;default=0;}
        private MainWin win;
        //private int x_list;
        //private int y_list;
        private Gtk.MenuItem last_selected = null;

        [GtkChild]
        private Gtk.ScrolledWindow keywordscrolled;

        [GtkChild]
        internal Gtk.MenuBar keywordmenu;
        //private Gtk.Box keywordbox;
        private string man_stdout;
        private string man_stderr;
        private int man_status;
        private string[] man_entries;
        private int max_show = 15;
        private int min_show = 5;
        //private Gtk.MenuItem menu_item;
        private int menu_item_height = -1;


        public KeywordList(MainWin win, string keyword/*, int width*/)
        {
            //int x_win,y_win,x_rel,y_rel;
            //int x_list,y_list;

            this.win = win;
            this.keyword = keyword;
            //this.decorated = true;
            try 
            {
                Process.spawn_command_line_sync ("man -k "+"\""+keyword+"\"",out man_stdout,out man_stderr,out man_status);
            } 
            catch (SpawnError e) 
            {
                message(e.message);
            }
            man_entries = man_stdout.split("\n");
            //print(man_stdout);
            //print("Found %d entries\n",man_entries.length);
            
            if (man_entries.length>0)
            {
                find_num = man_entries.length-1; // string.split() will add a "\n" string in the last
                man_entries=man_entries[0:find_num];
            }
            
            for (var index=0;index<find_num;index++)
            {
                //if (index>max_show)
                //    break;

                //print(man_entries[index]+"\n");
                //print(index.to_string()+"\n");
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
                //print("Height request %d\n",this.height_request);
            }
            
            this.set_attached_to(win);
            this.width_request = win.entry_search.get_allocated_width();

            /*
            win.scrolled.translate_coordinates(win,0,0,out x_rel,out y_rel);
            win.get_position(out x_win,out y_win);
            x_list=x_rel+x_win;
            y_list=y_rel+y_win+win.height_header;
            */
            //calculate_keyword_list_pos(win,out this.x_list,out this.y_list);
            update_keyword_list_pos(win);
            //this.move(this.x_list,this.y_list);
            Timeout.add(150,()=>{update_keyword_list_geom(this.win);return Source.CONTINUE;});
            //Idle.add(update_keyword_list_position);

            //this.set_keep_above(true);
            this.set_transient_for(win);
        }

        //private void calculate_keyword_list_pos(MainWin win, out int x, out int y)
        internal void update_keyword_list_pos(MainWin win)
        {
            //int x_win,y_win,x_rel,y_rel;
            //int x_list,y_list;
            Gtk.Allocation entry_allcation;
            Gdk.Window search_list_gdkwin;
            //win.search_list.show_all();
            if (this.get_realized())
            {
                win.entry_search.get_allocation(out entry_allcation);
                search_list_gdkwin = this.get_window();
                search_list_gdkwin.move_to_rect(entry_allcation,Gdk.Gravity.SOUTH_WEST,Gdk.Gravity.NORTH_WEST,Gdk.AnchorHints.RESIZE_Y,0,0);  
            }

            //win.scrolled.translate_coordinates(win,0,0,out x_rel,out y_rel);
            //win.get_position(out x_win,out y_win);
            //x=x_rel+x_win;
            //y=y_rel+y_win/*+win.height_header*/;

        }

        internal bool update_keyword_list_geom(MainWin win)
        {
            //print("update now!"+Time.local(time_t()).to_string()+"\n");
            
            //int width;
            //int x_list_new,y_list_new;
            int width_new;
            Gtk.MenuItem selected_item = null;

            if (this.get_realized())
            {
                update_keyword_list_pos(win);
            }
            //calculate_keyword_list_pos(this.win,out x_list_new,out y_list_new);
            /*
            if (((x_list_new-x_list).abs()+(x_list_new-y_list).abs())>1)
            {
                this.move(x_list_new,y_list_new);
            }*/
            
            width_new = win.entry_search.get_allocated_width();

            if ((this.visible)&&(width_new-this.width_request).abs()>1)
            {
                //print("here");

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
            /*
            if (selected_item!=null)
            {
                //print("here,");
                int item_x,item_y;
                Gtk.Adjustment vadj;

                selected_item.translate_coordinates(this,0,0,out item_x,out item_y);

                if (item_y>this.height_request)
                {
                    vadj = this.keywordscrolled.get_vadjustment();
                    vadj.value = vadj.value+menu_item_height*(max_show/2);
                    this.keywordmenu.select_item(selected_item);
                }
                else if(item_y<0)
                {
                    vadj = this.keywordscrolled.get_vadjustment();
                    vadj.value = vadj.value-menu_item_height*(max_show/2);
                    this.keywordmenu.select_item(selected_item);
                    //keywordview.vadjustment = keywordview.vadjustment-menu_item_height;
                }
                //print(item_x.to_string()+", "+item_y.to_string()+"\n");
            }*/

            return true;
        }

        [GtkCallback]
        private bool key_up_and_down(Gtk.Widget self,Gdk.Event evnt)
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
        private bool escape_key_destroy(Gtk.Widget self,Gdk.Event evnt)
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
        private bool mouse_leave_keyword_list(Gtk.Widget self,Gdk.Event evnt)
        {
            //print("mouse here!\n"+Time.local(time_t()).to_string()+"\n");
            Gdk.EventCrossing evnt_cross;
            
            evnt_cross = evnt.crossing;
            var x = evnt_cross.x;
            /* y value from EventCrossing incorrect, why?*/
            //var y = evnt_cross.y;
            //print(@"mouse here! $(x),$(y). "+Time.local(time_t()).to_string()+"\n");

            if ((last_selected!=null)&&((x<=0)||(x>=this.get_allocated_width())))
            {   
                
                //print(this.get_allocated_width().to_string()+"\n");
                this.keywordmenu.select_item(last_selected);
                //print("selected here\n");
                //print(((Gtk.MenuItem)keywordmenu.get_selected_item()).label+"\n");
            }

            return false;
        }
        
        private void navigate_to_uri(Gtk.MenuItem self)
        {
            //need further implementation
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
            this.win.view.load_uri(item_uri);  
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
