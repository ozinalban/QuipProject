import { LightningElement, api, wire, track } from "lwc";
import getCategoryTree from "@salesforce/apex/ProductCategoriesController.getCategoryTree";
const columns = [{ type: "text", fieldName: "name", label: "Category Name" }];

export default class ProductCategories extends LightningElement {
  columns = columns;
  jsonData = [];
  @track formattedData = [];

  categoryString =
    '[{ Id: "a058e000000efEpAAI", name: "Bilgisayar" },' +
    '{ Id: "a058e000000efEqAAI", name: "Elbise" },' +
    "];";

  categoryTree = [
    { Id: "a058e000000efEpAAI", name: "Bilgisayar" },
    { Id: "a058e000000efEqAAI", name: "Elbise" }
  ];

  categoryTree2 = [
    { Id: "a058e000000efEpAAI", name: "Bilgisayar" },
    { Id: "a058e000000efEqAAI", name: "Elbise" }
  ];

  @wire(getCategoryTree)
  generateCategoryTree({ error, data }) {
    if (data) {
      console.log("JSON Data : " + JSON.stringify(data));
      this.categoryTree = JSON.parse(JSON.stringify(data));
      console.log("categoryTree: " + this.categoryTree[1].category.Name);
      this.createTreeFromList();
    } else if (error) {
      this.error = error;
    }
  }

  createTreeFromList() {
    let tempString = "";
    for (let i = 0; i < this.categoryTree.length; i++) {
      if (this.categoryTree[i].category.Name != null) {
        /* let tempObj = {
          name: this.categoryTree[i].category.Name
        };*/

        tempString = '{"name":"' + this.categoryTree[i].category.Name + '"}';
        console.log(tempString);
        this.formattedData.push(JSON.parse(tempString));
      }
    }
    console.log("formattedData : " + JSON.stringify(this.formattedData));
  }
}