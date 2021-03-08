/*-
 * Authored by: XX Wu <xwuanhkust@gmail.com>
 */


namespace ManHelper
{   
    [GtkTemplate (ui = "/ui/bookmarks_dialog.ui")]
    
    private class BookmarksDialog:Gtk.Dialog
    {

        [GtkChild]
        Gtk.TreeView bookmarks_view;

        Gtk.ListStore list_store;
        Gtk.TreeIter list_iter;

        public BookmarksDialog()
        {
            list_store = new Gtk.ListStore(2,Type.STRING,Type.STRING);
            //list_store.iter
            list_store.append(out list_iter);
            //var get_iter_res = list_store.get_iter_first(out list_iter);    
            //print(get_iter_res.to_string());
            list_store.set(list_iter,0,"good",1,"good morning");
            //list_store.append(out list_iter);
            
            bookmarks_view.set_model(list_store);
            var column = new Gtk.TreeViewColumn();

            var title = new Gtk.CellRendererText();
            var author = new Gtk.CellRendererText();
            
            column.pack_start(title, true);
            column.pack_start(author, true);
            
            column.add_attribute(title, "text", 0);
            column.add_attribute(author, "text", 1);
            
            bookmarks_view.append_column(column);            
            //bookmarks_view.add_child();
        }
	}

    private class SelectQuery : Object 
    {
		/* "*" in SQL matches any number of any characters*/
        public string field { set; get; default = "*"; } 
        public string table { set; get; default = "bookmarks"; }
        public Gda.Connection connection { set; get; }
        
        public Gda.DataModel get_table_contents () throws Error requires (this.connection.is_opened())
        {
            print("Building query...\n");
            /* Build select query */
            var builder = new Gda.SqlBuilder(Gda.SqlStatementType.SELECT);
            builder.select_add_field (this.field, null, null);
            builder.select_add_target(this.table, null);

            var statement = builder.get_statement();
            print("Executing...\n");
            return this.connection.statement_execute_select(statement, null);
        }
    }

    class DataBase : Object 
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
                var q = new SelectQuery();
                q.connection = this.connection;
                this.show_data(q);
                //bookmarks_db.create_tables();               
            }
            catch (Error e)
            {
                message(e.message);
            }
        }

        public void open() throws Error 
        {
                print("Opening Database connection...\n");
                this.connection = Gda.Connection.open_from_string (null, this.db_file, null, Gda.ConnectionOptions.NONE);
        }

        /* Create a bookmark table */
        public void create_tables() throws Error requires (this.connection.is_opened())
        {
                print("Creating table...\n");
                this.run_query("CREATE TABLE IF NOT EXISTS bookmarks (title string PRIMARY KEY,uri string)");

        }
        
        public int run_query (string query) throws Error requires (this.connection.is_opened())
        {
                print(@"Executing query: [$(query)]\n");
                return this.connection.execute_non_select_command (query);
        }

        public void show_data (SelectQuery query) throws Error requires (this.connection.is_opened())
        {
            try 
            {
                var contents = query.get_table_contents();
                print("Table: '%s'\n%s", query.table, contents.dump_as_string());
            }
            catch  (GLib.Error e)
            {
                message(e.message);
            }
        }
}
}
