//
//  AccessoriesStoreView.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import SwiftUI

struct AccessoriesStoreView: View {
    @StateObject private var telecomAPI = TelecomAPIService()
    @State private var selectedCategory: Product.ProductCategory = .router
    @State private var searchText = ""
    @State private var showingCart = false
    @State private var cartItems: [Product] = []
    
    var filteredProducts: [Product] {
        let categoryFiltered = telecomAPI.products.filter { $0.category == selectedCategory }
        
        if searchText.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { product in
                product.name.localizedCaseInsensitiveContains(searchText) ||
                product.description.localizedCaseInsensitiveContains(searchText) ||
                (product.brand?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText)
                
                // Category Selector
                CategorySelector(selectedCategory: $selectedCategory)
                
                // Loading State
                if telecomAPI.isLoading {
                    LoadingView()
                } else if let errorMessage = telecomAPI.errorMessage {
                    ErrorView(message: errorMessage) {
                        Task {
                            await telecomAPI.fetchProductsByCategory(selectedCategory)
                        }
                    }
                } else if filteredProducts.isEmpty {
                    EmptyStateView(category: selectedCategory, searchText: searchText)
                } else {
                    ProductsGrid(products: filteredProducts, cartItems: $cartItems)
                }
                
                Spacer()
            }
            .navigationTitle("Accessories Store")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCart = true
                    }) {
                        ZStack {
                            Image(systemName: "bag")
                                .font(.title3)
                            
                            if !cartItems.isEmpty {
                                Text("\(cartItems.count)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 16, height: 16)
                                    .background(Color.red)
                                    .cornerRadius(8)
                                    .offset(x: 8, y: -8)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCart) {
                CartView(items: $cartItems)
            }
            .onAppear {
                Task {
                    await telecomAPI.fetchAllProducts()
                }
            }
            .onChange(of: selectedCategory) { newCategory in
                Task {
                    await telecomAPI.fetchProductsByCategory(newCategory)
                }
            }
            .refreshable {
                Task {
                    await telecomAPI.fetchProductsByCategory(selectedCategory)
                }
            }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading Products...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Fetching latest telecom equipment from ASUS, NETGEAR, TP-Link, and Ubiquiti")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Failed to Load Products")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search products...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top)
    }
}

struct CategorySelector: View {
    @Binding var selectedCategory: Product.ProductCategory
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Product.ProductCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

struct CategoryChip: View {
    let category: Product.ProductCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(category.rawValue)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct ProductsGrid: View {
    let products: [Product]
    @Binding var cartItems: [Product]
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(products) { product in
                    ProductCard(product: product, cartItems: $cartItems)
                }
            }
            .padding()
        }
    }
}

struct ProductCard: View {
    let product: Product
    @Binding var cartItems: [Product]
    @State private var showingDetail = false
    
    var isInCart: Bool {
        cartItems.contains { $0.id == product.id }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Product Image
            AsyncImage(url: URL(string: product.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: iconForCategory(product.category))
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    )
            }
            .frame(height: 120)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                // Brand and name
                VStack(alignment: .leading, spacing: 2) {
                    if let brand = product.brand {
                        Text(brand)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    
                    Text(product.name)
                        .font(.headline)
                        .lineLimit(2)
                }
                
                // Rating
                if let rating = product.rating {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        Text("(\(rating, specifier: "%.1f"))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(product.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Price and stock info
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("$\(product.price, specifier: "%.2f")")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            if let originalPrice = product.originalPrice, originalPrice > product.price {
                                Text("$\(originalPrice, specifier: "%.2f")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .strikethrough()
                            }
                        }
                        
                        if let stockCount = product.stockCount, stockCount > 0 {
                            Text("\(stockCount) in stock")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                    
                    Spacer()
                    
                    if !product.inStock {
                        Text("Out of Stock")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
            
            // Action Buttons
            HStack(spacing: 8) {
                Button(action: {
                    showingDetail = true
                }) {
                    Text("Details")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                }
                
                Button(action: {
                    if isInCart {
                        cartItems.removeAll { $0.id == product.id }
                    } else {
                        cartItems.append(product)
                    }
                }) {
                    Text(isInCart ? "Remove" : "Add")
                        .font(.caption)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isInCart ? Color.red : Color.green)
                        .cornerRadius(6)
                }
                .disabled(!product.inStock && !isInCart)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showingDetail) {
            ProductDetailSheet(product: product, cartItems: $cartItems)
        }
    }
    
    private func iconForCategory(_ category: Product.ProductCategory) -> String {
        switch category {
        case .router: return "wifi.router"
        case .extender: return "antenna.radiowaves.left.and.right"
        case .mesh: return "network"
        case .cable: return "cable.connector"
        case .accessory: return "gear"
        case .modem: return "externaldrive.connected.to.line.below"
        case .antenna: return "dot.radiowaves.up.forward"
        }
    }
}

struct EmptyStateView: View {
    let category: Product.ProductCategory
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            if searchText.isEmpty {
                Text("No \(category.rawValue.lowercased())s available")
                    .font(.headline)
                Text("Check back later for new products")
                    .foregroundColor(.secondary)
            } else {
                Text("No results found")
                    .font(.headline)
                Text("Try searching for something else")
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct ProductDetailSheet: View {
    let product: Product
    @Binding var cartItems: [Product]
    @Environment(\.dismiss) var dismiss
    
    var isInCart: Bool {
        cartItems.contains { $0.id == product.id }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Product Image
                    AsyncImage(url: URL(string: product.imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .foregroundColor(.gray.opacity(0.3))
                            .aspectRatio(1, contentMode: .fit)
                    }
                    .frame(height: 250)
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Brand and Category
                        HStack {
                            if let brand = product.brand {
                                Text(brand)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                            
                            Spacer()
                            
                            Text(product.category.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(6)
                        }
                        
                        Text(product.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        // Rating
                        if let rating = product.rating {
                            HStack(spacing: 4) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                                        .foregroundColor(.orange)
                                }
                                Text("(\(rating, specifier: "%.1f"))")
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .font(.subheadline)
                        }
                        
                        Text(product.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        // Tags
                        if let tags = product.tags, !tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                }
                                .padding(.horizontal, 1)
                            }
                        }
                        
                        // Price and Stock
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Text("$\(product.price, specifier: "%.2f")")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                    
                                    if let originalPrice = product.originalPrice, originalPrice > product.price {
                                        Text("$\(originalPrice, specifier: "%.2f")")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                            .strikethrough()
                                    }
                                }
                                
                                if let stockCount = product.stockCount, stockCount > 0 {
                                    Text("\(stockCount) units available")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                            
                            Spacer()
                            
                            if product.inStock {
                                Text("In Stock")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(6)
                            } else {
                                Text("Out of Stock")
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                        
                        // Specifications
                        if let specifications = product.specifications, !specifications.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Specifications")
                                    .font(.headline)
                                
                                ForEach(specifications.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                    SpecificationRow(title: key, value: value)
                                }
                            }
                        } else {
                            // Mock specifications
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Specifications")
                                    .font(.headline)
                                
                                if let brand = product.brand {
                                    SpecificationRow(title: "Brand", value: brand)
                                } else {
                                    SpecificationRow(title: "Brand", value: "Etell")
                                }
                                SpecificationRow(title: "Warranty", value: "2 years")
                                SpecificationRow(title: "Compatibility", value: "Universal")
                                
                                if product.category == .router {
                                    SpecificationRow(title: "WiFi Standard", value: "WiFi 6 (802.11ax)")
                                    SpecificationRow(title: "Speed", value: "Up to 1200 Mbps")
                                    SpecificationRow(title: "Range", value: "Up to 3000 sq ft")
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isInCart ? "Remove from Cart" : "Add to Cart") {
                        if isInCart {
                            cartItems.removeAll { $0.id == product.id }
                        } else {
                            cartItems.append(product)
                        }
                    }
                    .disabled(!product.inStock && !isInCart)
                }
            }
        }
    }
}

struct SpecificationRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

struct CartView: View {
    @Binding var items: [Product]
    @Environment(\.dismiss) var dismiss
    
    var totalPrice: Double {
        items.reduce(0) { $0 + $1.price }
    }
    
    var body: some View {
        NavigationView {
            if items.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bag")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Your cart is empty")
                        .font(.headline)
                    
                    Text("Add some products to get started")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("Cart")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
            } else {
                VStack {
                    List {
                        ForEach(items) { item in
                            CartItemRow(product: item) {
                                items.removeAll { $0.id == item.id }
                            }
                        }
                    }
                    
                    // Checkout Section
                    VStack(spacing: 16) {
                        HStack {
                            Text("Total")
                                .font(.headline)
                            Spacer()
                            Text("$\(totalPrice, specifier: "%.2f")")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        Button(action: {
                            // Handle checkout
                            items.removeAll()
                            dismiss()
                        }) {
                            Text("Checkout")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                }
                .navigationTitle("Cart (\(items.count))")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

struct CartItemRow: View {
    let product: Product
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: product.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.3))
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(product.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("$\(product.price, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Button("Remove") {
                    onRemove()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AccessoriesStoreView()
}
