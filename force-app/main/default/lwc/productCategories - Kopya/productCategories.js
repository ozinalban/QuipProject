import { LightningElement, api, wire, track } from "lwc";
import getCategoryTree from "@salesforce/apex/ProductCategoriesController.getCategoryTree";
const columns = [{ type: "text", fieldName: "name", label: "Category Name" }];

export default class ProductCategories extends LightningElement {
  columns = columns;

  @track categoryTree = [];
  @track selectedRows = [];
  @track currentSelectedRows;  // used to track changes

  @wire(getCategoryTree)
  generateCategoryTree({ error, data }) {
    if (data) {
      console.log("JSON Data : " + JSON.stringify(data));
      this.categoryTree = JSON.parse(JSON.stringify(data));
      //console.log("categoryTree: " + this.categoryTree[1].category.Name);
      this.categoryTree = this.createTreeFromList(this.categoryTree);
    } else if (error) {
      this.error = error;
      debugger;
    }
  }

  createTreeFromList(categoryObject) {
    console.log('categoryObject.length' + categoryObject.length);
    let counter = 0;
    if(categoryObject.length !== 0 ){
      for (let i = 0; i < categoryObject.length; i++) {
        if (categoryObject[i] != null) {
          console.log('categoryObject[i].name : ' + categoryObject[i].name);
          
          if(categoryObject[i].children.length !== 0){
            categoryObject[i]._children = [];
            categoryObject[i]._children = this.createTreeFromList(categoryObject[i].children);

            delete categoryObject[i].children;
            console.log('children deleted');

          }
        }
      }
    }
    console.log("formattedData : " + JSON.stringify(categoryObject));
    return categoryObject;
  }


  handleRowselection (event){
    var selectRows = event.detail.selectedRows;

    console.log('Selected Rows : ' + JSON.stringify(selectRows));
      if(selectRows.length > 0){
        selectRows.forEach(function (selectedCategory){
            if (selectedCategory.hasChildren){
              console.log('call selectChildCategories method!');
              this.selectChildCategories(selectedCategory);
            }
        })

      }
      debugger;
  }

  selectChildCategories(selectedCategory){
    console.log('selectChildCategories Entry');
    console.log('category in selectChildCategories : ' + JSON.stringify(selectedCategory));
    if (selectedCategory.hasChildren){
      let childCategories = categoryTree.filter(childCategory => childCategory.parentCategoryId == selectedCategory.id);
      childCategories.forEach(function(category){
        const pos = this.selectedRows.map(e => e.id).indexOf(category.id);
        if(pos !== -1){
          this.selectedRows.push(category);
        }
      });
    }
  }

  handleToggle (event){
    console.log('Toggled Category Name: ' + event.detail.name);
  }

} 