// ProductService.swift - Firebase Firestore Integration
import Foundation
import FirebaseFirestore

@MainActor
class ProductService: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    func fetchProducts() {
        isLoading = true
        errorMessage = nil
        
        db.collection("products")
            .whereField("inStock", isEqualTo: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = "Failed to load products: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        self?.products = []
                        return
                    }
                    
                    self?.products = documents.compactMap { document in
                        try? document.data(as: Product.self)
                    }
                }
            }
    }
    
    func fetchProductsByCategory(_ category: Product.ProductCategory) {
        isLoading = true
        
        db.collection("products")
            .whereField("category", isEqualTo: category.rawValue)
            .whereField("inStock", isEqualTo: true)
            .getDocuments { [weak self] querySnapshot, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.errorMessage = "Failed to load products: \(error.localizedDescription)"
                        return
                    }
                    
                    guard let documents = querySnapshot?.documents else {
                        self?.products = []
                        return
                    }
                    
                    self?.products = documents.compactMap { document in
                        try? document.data(as: Product.self)
                    }
                }
            }
    }
    
    func addProduct(_ product: Product) async throws {
        try await db.collection("products").document(product.id).setData(from: product)
    }
    
    func updateStock(productId: String, inStock: Bool) async throws {
        try await db.collection("products").document(productId).updateData([
            "inStock": inStock
        ])
    }
}

// Usage example for Firestore data structure:
/*
Collection: "products"
Document: "product_id"
{
  "id": "wifi6_router_001",
  "name": "ASUS WiFi 6 Router",
  "description": "High-performance WiFi 6 router with advanced features",
  "price": 199.99,
  "imageURL": "https://your-cdn.com/images/router1.jpg",
  "category": "Router",
  "inStock": true,
  "specifications": {
    "speed": "AX3000",
    "coverage": "3000 sq ft",
    "ports": 4
  },
  "rating": 4.5,
  "reviewCount": 127
}
*/
