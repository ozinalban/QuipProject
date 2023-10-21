public without sharing class ProductCategoriesController {
  @AuraEnabled(cacheable=true)
  public static List<CategoryTreeNode> getCategoryTree() {
    List<CategoryTreeNode> categoryTree = new List<CategoryTreeNode>();
    Map<Id, CategoryTreeNode> categoryMap = new Map<Id, CategoryTreeNode>();

    // Query all categories
    List<Category__c> allCategories = [
      SELECT Id, name, parentCategory__c
      FROM Category__c
      ORDER BY parentCategory__c NULLS FIRST

    ];
  

    // Create top-level nodes and populate the map
    for (Category__c category : allCategories) {
      CategoryTreeNode node = new CategoryTreeNode(category);
      categoryMap.put(category.Id, node);
      if (category.ParentCategory__c == null) {
        categoryTree.add(node);
      }
    }

    // Build the hierarchy
    for (Category__c category : allCategories) {
      if (category.ParentCategory__c != null) {
        CategoryTreeNode parentNode = categoryMap.get(
          category.ParentCategory__c
        );
        if (parentNode != null) {
          CategoryTreeNode childNode = categoryMap.get(category.Id);
          if (childNode != null) {
            parentNode.children.add(childNode);
          }
        }
      }
    }

    return categoryTree;
  }

  public class CategoryTreeNode {
    @AuraEnabled
    public Category__c category;
    @AuraEnabled
    public String id;
    @AuraEnabled
    public String name;
    @AuraEnabled
    public String parentCategory;
    @AuraEnabled
    public List<CategoryTreeNode> children;

    public CategoryTreeNode(Category__c category) {
      this.category = category;
      this.children = new List<CategoryTreeNode>();
    }
  }
}