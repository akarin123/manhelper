/*-
 * Authored by: XX Wu <xwuanhkust@gmail.com>
 */

/*
1. need to implement up and down keybindings for the search list
*/

namespace ManHelper
{   
    //Add search list for man pages
    [GtkTemplate (ui = "/ui/keyword_list.ui")]
    private class KeywordList:Gtk.Window
    //private class SearchWindow:Gtk.Menu
    {
        public string keyword {get;set;default="";}
        public int find_num  {get;set;default=0;}
        private MainWin win;

        [GtkChild]
        private Gtk.MenuBar keywordbar;
        //private Gtk.Box keywordbox;
        private string man_stdout;
        private string man_stderr;
        private int man_status;
        private string[] man_entries;
        private int max_show = 25;

        public KeywordList(MainWin win, string keyword, int width)
        {
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
                if (index>max_show)
                    break;

                //print(man_entries[index]+"\n");
                //print(index.to_string()+"\n");
                var menu_item = new Gtk.MenuItem.with_label(man_entries[index]); 
                menu_item.activate.connect(navigate_to_uri);
                keywordbar.append(menu_item);
            }

            this.width_request=width;
            this.set_keep_above(true);
        }

        private void navigate_to_uri(Gtk.MenuItem self)
        {
            //need further implementation
            //Gtk.MenuItem selected_item;
            string man_entry;
            string[] man_data;
            string sec_index="";
            string item_uri="";
            //selected_item = this.keywordbar.get_selected_item() as Gtk.MenuItem; 

            man_entry = self.get_label();
            man_data= man_entry.split(" ");

            sec_index=man_data[1].replace("(","").replace(")","");
            //print(man_data[0]+"."+sec_index+"\n");
            item_uri="http://localhost/cgi-bin/man/man2html?"+sec_index+"+"+man_data[0].strip();
            this.win.view.load_uri(item_uri);  
            this.destroy();
        }
    }
}
