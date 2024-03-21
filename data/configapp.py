import tkinter as tk
from tkinter import simpledialog

class ItemManagerGUI:
    def __init__(self, master):
        self.master = master
        self.master.title("Item Manager")
        
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
            with open("items.txt", "r") as file:
                for line in file:
                    value, name = line.strip().split(',')
                    self.items.append((value, name))
        except FileNotFoundError:
            pass
        self.refresh_listbox()

    def save_items(self):
        with open("items.txt", "w") as file:
            for value, name in self.items:
                file.write(f"{value},{name}\n")

    def refresh_listbox(self):
        self.listbox.delete(0, tk.END)
        for item in self.items:
            self.listbox.insert(tk.END, f"{item[0]}, {item[1]}")

    def add_item(self):
        value = simpledialog.askstring("Input", "Enter value", parent=self.master)
        name = simpledialog.askstring("Input", "Enter name", parent=self.master)
        if value and name:
            self.items.append((value, name))
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
            value, name = self.items[index]

            new_value = simpledialog.askstring("Input", "Enter new value", initialvalue=value, parent=self.master)
            new_name = simpledialog.askstring("Input", "Enter new name", initialvalue=name, parent=self.master)
            
            if new_value and new_name:
                self.items[index] = (new_value, new_name)
                self.refresh_listbox()
                self.save_items()
        except IndexError:
            pass

def main():
    root = tk.Tk()
    app = ItemManagerGUI(root)
    root.mainloop()

if __name__ == "__main__":
    main()