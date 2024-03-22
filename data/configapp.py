import tkinter as tk
from tkinter import simpledialog, ttk
import sys
from tkinter import font
class MultiInputDialog(simpledialog.Dialog):
    def __init__(self, master, items=None):
        self.items = items
        super().__init__(master)

    def body(self, master):
        self.title("Add Item")

        print(self.items)

        tk.Label(master, text="Name:").grid(row=0)
        self.name_entry = tk.Entry(master)
        self.name_entry.grid(row=0, column=1)            
        
        tk.Label(master, text="Path:").grid(row=1)
        self.path_entry = tk.Entry(master)
        self.path_entry.grid(row=1, column=1)

        tk.Label(master, text="Distance:").grid(row=2)
        self.distance_entry = tk.Entry(master)
        self.distance_entry.grid(row=2, column=1)

        tk.Label(master, text="Width:").grid(row=3)
        self.width_entry = tk.Entry(master)
        self.width_entry.grid(row=3, column=1)

        tk.Label(master, text="BRDF Model:").grid(row=4)
        self.categories = ['ON', 'CT']
        self.brdf = ttk.Combobox(master, values=self.categories, state="readonly")
        self.brdf.grid(row=4, column=1)

        default_category = 'ON'
        self.brdf.set(default_category)

        tk.Label(master, text="Roughness:").grid(row=5)
        self.roughness_entry = tk.Entry(master)
        self.roughness_entry.grid(row=5, column=1)

        tk.Label(master, text="Fresnel Constant:").grid(row=6)
        self.fresnel_entry = tk.Entry(master)
        self.fresnel_entry.grid(row=6, column=1)

        if self.items:
            self.name_entry.insert(0, self.items[0])
            self.path_entry.insert(0, self.items[1])
            self.distance_entry.insert(0, self.items[2])
            self.width_entry.insert(0, self.items[3])
            self.brdf.set(self.items[4])
            self.roughness_entry.insert(0, self.items[5])
            self.fresnel_entry.insert(0, self.items[6])

        
        return self.name_entry

    def apply(self):
        self.result = (self.name_entry.get(), self.path_entry.get(), self.distance_entry.get(), self.width_entry.get(), self.brdf.get(), self.roughness_entry.get(), self.fresnel_entry.get())

class ItemManagerGUI:
    def __init__(self, master):
        self.master = master
        self.master.title("Material Calibration Manager")
        
        self.frame = tk.Frame(self.master)
        self.frame.pack(fill=tk.BOTH, expand=True)

        self.listbox = tk.Listbox(self.frame)
        self.listbox.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

        self.scrollbar = tk.Scrollbar(self.frame, orient="vertical", command=self.listbox.yview)
        self.scrollbar.pack(side=tk.LEFT, fill="y")

        self.listbox.config(yscrollcommand=self.scrollbar.set)

        self.addButton = tk.Button(self.master, text="Add", command=self.add_item)
        self.addButton.pack(fill=tk.X)

        self.editButton = tk.Button(self.master, text="Edit", command=self.edit_item)
        self.editButton.pack(fill=tk.X)

        self.removeButton = tk.Button(self.master, text="Remove", command=self.remove_item)
        self.removeButton.pack(fill=tk.X)

        self.load_items()

    def load_items(self):
        self.items = []
        try:
            with open(sys.argv[1], "r") as file:
                for line in file:
                    name, path, distance, width, brdf, roughness, fresnel = line.strip().split(',')
                    self.items.append((name, path, distance, width, brdf, roughness, fresnel))
        except FileNotFoundError:
            pass
        self.refresh_listbox()

    def save_items(self):
        with open(sys.argv[1], "w") as file:
            for name, path, distance, width, brdf, roughness, fresnel in self.items:
                file.write(f"{name},{path},{distance},{width},{brdf},{roughness},{fresnel}\n")

    def refresh_listbox(self):
        self.listbox.delete(0, tk.END)
        for item in self.items:
            self.listbox.insert(tk.END, f"{item[0]}, {item[1]}, {item[2]}, {item[3]}, {item[4]}, {item[5]}, {item[6]}")

    def add_item(self):
        dialog = MultiInputDialog(self.master)
        print(dialog.result)
        if dialog.result:
            name, path, distance, width, brdf, roughness, fresnel = dialog.result
            self.items.append((name, path, distance, width, brdf, roughness, fresnel))
            self.refresh_listbox()
            self.save_items()

    def remove_item(self):
        try:
            index = self.listbox.curselection()[0]
            del self.items[index]
            self.refresh_listbox()
            self.save_items()
        except IndexError:
            pass

    def edit_item(self):
        try:
            index = self.listbox.curselection()[0]
            name, path, distance, width, brdf, roughness, fresnel = self.items[index]

            dialog = MultiInputDialog(self.master, (name, path, distance, width, brdf, roughness, fresnel))
            if dialog.result:
                name, path, distance, width, brdf, roughness, fresnel = dialog.result
                self.items[index] = (name, path, distance, width, brdf, roughness, fresnel)
                self.refresh_listbox()
                self.save_items()

        except IndexError:
            pass

def main():
    root = tk.Tk()
    default_font = font.nametofont("TkDefaultFont")
    default_font.configure(size=12)
    root.geometry("800x600")
    app = ItemManagerGUI(root)
    root.mainloop()

if __name__ == "__main__":
    main()