/*-
 * Authored by: XX Wu <xwuanhkust@gmail.com>
 */

namespace ManHelper
{   
    /*Add multitabs for scrolled window*/
    [GtkTemplate (ui = "/ui/multitab_pager.ui")]
    internal class MultitabPager: Gtk.Notebook
    {
        MainWin win;
        string page_no = "Page No.";

        [GtkChild]
        internal Gtk.ScrolledWindow first_scrolled;
        [GtkChild]
        internal Gtk.Label first_label;
        [GtkChild]
        internal Gtk.Image image_close;

        public int n_pages {get {return this.get_n_pages();}}
        
        public MultitabPager(MainWin win)
        {
            WebKit.WebView view; 
            this.win = win;
            win.pager = this;
            view = new WebKit.WebView();  
            //view.button_press_event.connect(on_view_mouse_press);
            this.first_scrolled.add_with_properties(view);

            win.view_current = view;
        }

        public void append_manpage()
        {
            var new_scrolled = new Gtk.ScrolledWindow(null,null);
            var label_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL,0);
            this.append_page(new_scrolled,label_box);

            var page_label = new Gtk.Label("Page "+this.n_pages.to_string());
            var btn_page_close = new Gtk.Button();
            var image_dup = new Gtk.Image();

            string icon_name;
            Gtk.IconSize icon_size;
            image_close.get_icon_name(out icon_name,out icon_size);
            image_dup.set_from_icon_name(icon_name,icon_size);
            btn_page_close.set_image(image_dup);
            //print(icon_name+"\n");
            
            btn_page_close.set_relief(Gtk.ReliefStyle.NONE);
            label_box.pack_start(page_label,false,true,0);
            label_box.pack_start(btn_page_close,false,true,0);
            btn_page_close.set_data<int>(page_no,this.n_pages);
            btn_page_close.clicked.connect(on_btn_page_close_clicked);
            
            var new_view = new WebKit.WebView(); 
            //win.view += new_view; /* Dynamically increase the view array */
            //new_view.button_press_event.connect(on_view_mouse_press);
            new_scrolled.add_with_properties(new_view);
            new_scrolled.set_data<WebKit.WebView>("view",new_view);
            new_scrolled.set_data<Gtk.Button>("button",btn_page_close);
            //print(res.to_string()+"\n");
            new_scrolled.show_all();
            label_box.show_all();

            //print(this.get_n_pages().to_string()+"\n");
        }
        
        public void on_btn_page_close_clicked(Gtk.Button self)
        {
            var page_index = self.get_data<int>(page_no);

            this.remove_page(page_index-1);
            
            // need to update page_no of each button after the closed page 
        }

        [GtkCallback]
        private void on_page_switched(Gtk.Widget page,uint page_num)
        {
            //print("hello!\n");
            win.view_current = page.get_data<WebKit.WebView>("view");

           //win.view_current.load_uri("https://developer.gnome.org/icon-naming-spec/");
        }
    }

}
