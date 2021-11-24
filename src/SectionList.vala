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
    /* List sections of the man pages*/
    [GtkTemplate (ui = "/ui/section_list.ui")]
    internal class SectionList: Gtk.Box
    {
        MainWin win;

        [GtkChild]
        internal unowned Gtk.ComboBox section_combo;

        internal SectionList(MainWin win)
        {
            Gtk.TreeIter section_list_iter;
            this.win = win;

            var section_list_store = new Gtk.ListStore(2, typeof(string), typeof(string));
            section_list_store.append(out section_list_iter);
            section_list_store.set(section_list_iter,0," ",1,"All Sections",-1);
            section_list_store.append(out section_list_iter);
            section_list_store.set(section_list_iter,0,"1:",1,"User Commands",-1);
            section_list_store.append(out section_list_iter);
            section_list_store.set(section_list_iter,0,"2:",1,"System Calls",-1);
            section_list_store.append(out section_list_iter);
            section_list_store.set(section_list_iter,0,"3:",1,"Library Functions",-1);
            section_list_store.append(out section_list_iter);
            section_list_store.set(section_list_iter,0,"4:",1,"Special Files",-1);
            section_list_store.append(out section_list_iter);
            section_list_store.set(section_list_iter,0,"5:",1,"File Formats",-1);
            section_list_store.append(out section_list_iter);
            section_list_store.set(section_list_iter,0,"6:",1,"Games",-1);
            section_list_store.append(out section_list_iter);
            section_list_store.set(section_list_iter,0,"7:",1,"Miscellany",-1);
            section_list_store.append(out section_list_iter);
            section_list_store.set(section_list_iter,0,"8:",1,"Administration",-1);
            section_combo.set_model(section_list_store);

            var cellrender1 = new Gtk.CellRendererText();
            section_combo.pack_start(cellrender1, true);
            section_combo.add_attribute(cellrender1, "text", 0);
            var cellrender2 = new Gtk.CellRendererText();
            section_combo.pack_start(cellrender2, true);
            section_combo.add_attribute(cellrender2, "text", 1);
            
            section_combo.set_active(0);
        }
    }
}