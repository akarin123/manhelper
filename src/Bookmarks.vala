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
* along with Akira. If not, see <https://www.gnu.org/licenses/>.
*
* Authored by: XX Wu <xwuanhkust@gmail.com>
*/

namespace ManHelper
{   
    [GtkTemplate (ui = "/ui/bookmarks_dialog.ui")]
    
    private class BookmarksDialog:Gtk.Dialog
    {

        [GtkChild]
        private Gtk.TreeView bookmarks_view;

        private MainWin win;
        private Gtk.ListStore list_store;
        private Gtk.TreeIter list_iter;

        public BookmarksDialog(MainWin win)
        {
            this.win = win;
            list_store = new Gtk.ListStore(1,Type.STRING);

            bookmarks_view.set_model(list_store);
            var column = new Gtk.TreeViewColumn();

            var title = new Gtk.CellRendererText();
            //var intro = new Gtk.CellRendererText();
            
            column.pack_start(title, true);
            column.set_attributes(title, "text", 0);

            bookmarks_view.append_column(column);       
      
            var query = new SelectQuery();
            var bookmarks_db = win.app.bookmarks_db;
            query.connection = bookmarks_db.connection;
            //win.bookmarks_db.show_data(query);
            try
            {
                var contents = query.get_table_contents();

                var len_bookmarks = contents.get_n_rows();

                //print(@"$(len_bookmarks) bookmarks\n");
                for (var ii=0;ii<len_bookmarks;ii++)
                {
                    list_store.append(out list_iter);
                    list_store.set(list_iter,0,contents.get_value_at(0,ii).get_string());
                    //print("%s,%s\n",contents.get_value_at(0,ii).get_string(),contents.get_value_at(1,ii).get_string());
                }
            }
            catch (Error e)
            {
                message(e.message);
            }
            
            this.set_transient_for(win);
            //bookmarks_view.add_child();
        }

        [GtkCallback]
        private void on_btn_load_clicked(Gtk.Button self)
        {            
            var query = new SelectQuery();
            var bookmarks_db = this.win.app.bookmarks_db;
            
            query.connection = bookmarks_db.connection;
            
            Gtk.TreeModel tree_model;
            Gtk.TreeIter tree_iter;
            bool selected;
            //win.bookmarks_db.show_data(query);
            var selection = this.bookmarks_view.get_selection();
            selected = selection.get_selected(out tree_model, out tree_iter);

            if (selected)
            {
                try
                {
                    Value title_v;
                    tree_model.get_value(tree_iter,0,out title_v);

                    SList<Value?> title_list = new SList<Value?>();
                    //print("title: %s\n",title_v.get_string());
                    title_list.append(title_v);

                    //title_list.append("man");
                    var contents = query.get_table_contents();
                    var row_num = contents.get_row_from_values(title_list,{0});
                    //print(@"row num: $(row_num)\n");
                    //print(contents.get_value_at(1,row_num).get_string()+"\n");

                    var uri = contents.get_value_at(1,row_num).get_string();
                    this.win.view_current.load_uri(uri);

                    title_v.unset();
                }
                catch (Error e)
                {
                    message(e.message);
                }
            }
        }
    
        [GtkCallback]
        private void on_btn_delete_clicked(Gtk.Button self)
        {
            var query = new SelectQuery();
            var bookmarks_db = this.win.app.bookmarks_db;
            
            query.connection = bookmarks_db.connection;
            
            Gtk.TreeModel tree_model;
            Gtk.TreeIter tree_iter;
            bool selected;
            //win.bookmarks_db.show_data(query);
            var selection = this.bookmarks_view.get_selection();
            selected = selection.get_selected(out tree_model, out tree_iter);

            if (selected)
            {
                try
                {
                    Value title_v;
                    tree_model.get_value(tree_iter,0,out title_v);

                    string title = title_v.get_string();

                    bookmarks_db.run_query(@"DELETE FROM bookmarks WHERE title = \"$(title)\""); 
                    ((Gtk.ListStore)tree_model).remove(ref tree_iter);
                    
                    title_v.unset();
                }
                catch (Error e)
                {
                    message(e.message);
                }
            }
        }    

        [GtkCallback]
        private void on_btn_close_clicked(Gtk.Button self)
        {
            this.destroy();
        }    
	}
    

    private class SelectQuery:Object 
    {
		/* "*" in SQL matches any number of any characters */
        public string field { set; get; default = "*"; } 
        public string table { set; get; default = "bookmarks"; }
        public Gda.Connection connection { set; get; }
        
        public Gda.DataModel get_table_contents () throws Error requires (this.connection.is_opened())
        {
            //print("Building query...\n");
            /* Build select query */
            var builder = new Gda.SqlBuilder(Gda.SqlStatementType.SELECT);
            builder.select_add_field (this.field, null, null);
            builder.select_add_target(this.table, null);

            var statement = builder.get_statement();
            //print("Executing...\n");
            return this.connection.statement_execute_select(statement, null);
        }
    }

    internal class DataBase:Object 
    {
        /* Using defaults will search a SQLite database located at current directory called bookmarks.db*/
        public string provider { set; get; default = "SQLite"; }
        public string db_file { set; get; default = "SQLite://DB_DIR=.;DB_NAME=bookmarks"; }
        public Gda.Connection connection;

        public DataBase(string path,string filename)
        {
            this.db_file = "SQLite://DB_DIR="+path+";DB_NAME="+filename;

            try
            {
                this.open();
                this.create_tables();  
                //var q = new SelectQuery();
                //q.connection = this.connection;
                //this.show_data(q);
                //bookmarks_db.create_tables();               
            }
            catch (Error e)
            {
                message(e.message);
            }
        }

        public static void init_database_directory(App app)
        {
            var home_dir = Environment.get_home_dir();

            if (home_dir!=null)
            {
                //print(home_dir+"\n");
                var bookmarks_dirpath = home_dir+app.bookmarks_directory;
                
                if (FileUtils.test(bookmarks_dirpath, FileTest.IS_DIR))
                {
                    app.bookmarks_parent_dir = home_dir;
                }
                else
                {
                    var file_temp = File.new_for_path(bookmarks_dirpath);
                    try
                    {
                        if (file_temp.make_directory(null))
                        {
                            app.bookmarks_parent_dir = home_dir;
                        }
                    }
                    catch (Error e)
                    {
                        message(e.message);
                    }
                    

                }
            }
        }
        public void open() throws Error 
        {
                //print("Opening Database connection...\n");
                this.connection = Gda.Connection.open_from_string (null, this.db_file, null, Gda.ConnectionOptions.NONE);
        }

        /* Create a bookmark table */
        public void create_tables() throws Error requires (this.connection.is_opened())
        {
                //print("Creating table...\n");
                this.run_query("CREATE TABLE IF NOT EXISTS bookmarks (title string PRIMARY KEY,uri string)");

        }
        
        public int run_query (string query) throws Error requires (this.connection.is_opened())
        {
                //print(@"Executing query: [$(query)]\n");
                return this.connection.execute_non_select_command (query);
        }

        /*
        public void show_data (SelectQuery query) throws Error requires (this.connection.is_opened())
        {
            try 
            {
                var contents = query.get_table_contents();
                
                //print("Table: '%s'\n%s", query.table, contents.dump_as_string());
                //print("Table: \n%s", contents.dump_as_string());
            }
            catch  (GLib.Error e)
            {
                message(e.message);
            }
        }*/
    }
}
