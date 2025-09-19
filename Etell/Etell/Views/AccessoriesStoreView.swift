//
//  AccessoriesStoreView.swift
//  Etell
//
//  Created by Geeneth 013 on 2025-08-16.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct AccessoriesStoreView: View {
    @StateObject private var telecomAPI = TelecomAPIService()
    @State private var selectedCategory: Product.ProductCategory = .router
    @State private var searchText = ""
    @State private var showingCart = false
    @State private var cartItems: [Product] = []
    @State private var isSearching = false
    
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
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Modern Search Bar
                    ModernStoreSearchBar(
                        searchText: $searchText,
                        isSearching: $isSearching
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // Modern Category Selector
                    ModernCategorySelector(selectedCategory: $selectedCategory)
                        .padding(.top, 12)
                    
                    // Content
                    if telecomAPI.isLoading {
                        ModernLoadingView()
                    } else if let errorMessage = telecomAPI.errorMessage {
                        ModernErrorView(message: errorMessage) {
                            Task {
                                await telecomAPI.fetchAllProducts()
                            }
                        }
                    } else if filteredProducts.isEmpty {
                        ModernEmptyStateView(category: selectedCategory, searchText: searchText)
                    } else {
                        ModernProductsGrid(products: filteredProducts, cartItems: $cartItems)
                    }
                }
            }
            .navigationTitle("Store")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ModernCartButton(cartItems: cartItems) {
                        showingCart = true
                    }
                }
            }
            .sheet(isPresented: $showingCart) {
                ModernCartView(items: $cartItems)
            }
            .onAppear {
                Task {
                    await telecomAPI.fetchAllProducts()
                }
            }
            .onChange(of: selectedCategory) { _, newCategory in
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

// MARK: - Modern UI Components

struct ModernStoreSearchBar: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 16, weight: .medium))
            
            TextField("Search products, brands, categories...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .onTapGesture {
                    isSearching = true
                }
                .onSubmit {
                    isSearching = false
                }
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    isSearching = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 16))
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(UIColor.quaternaryLabel), lineWidth: 0.5)
        )
        .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
    }
}

struct ModernCategorySelector: View {
    @Binding var selectedCategory: Product.ProductCategory
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Product.ProductCategory.allCases, id: \.self) { category in
                    ModernCategoryChip(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct ModernCategoryChip: View {
    let category: Product.ProductCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: iconForCategory(category))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? .white : .blue)
                
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(isSelected ? .white : .primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.blue.gradient)
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? .clear : Color(UIColor.quaternaryLabel), lineWidth: 0.5)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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

struct ModernCartButton: View {
    let cartItems: [Product]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Image(systemName: "bag")
                    .font(.title3)
                    .foregroundStyle(.primary)
                
                if !cartItems.isEmpty {
                    Text("\(cartItems.count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(.red, in: Circle())
                        .offset(x: 10, y: -10)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: cartItems.count)
    }
}

struct ModernLoadingView: View {
    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.2)
            
            VStack(spacing: 8) {
                Text("Loading Products")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text("Fetching the latest telecom equipment from top brands")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct ModernErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.orange)
                
                VStack(spacing: 8) {
                    Text("Unable to Load Products")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            
            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.blue.gradient, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct ModernEmptyStateView: View {
    let category: Product.ProductCategory
    let searchText: String
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: searchText.isEmpty ? "cube.box" : "magnifyingglass")
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)
                
                VStack(spacing: 8) {
                    if searchText.isEmpty {
                        Text("No \(category.rawValue.capitalized)s Available")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        Text("Check back later for new products in this category")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("No Results Found")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        Text("Try adjusting your search or browse different categories")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .padding(.horizontal, 32)
    }
}

struct ModernProductsGrid: View {
    let products: [Product]
    @Binding var cartItems: [Product]
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(products) { product in
                    ModernProductCard(product: product, cartItems: $cartItems)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 100) // Space for tab bar
        }
    }
}

struct ModernProductCard: View {
    let product: Product
    @Binding var cartItems: [Product]
    @State private var showingDetail = false
    @State private var isPressed = false
    
    var isInCart: Bool {
        cartItems.contains { $0.id == product.id }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Product Image Section
            ProductImageSection(
                product: product,
                isInCart: isInCart,
                iconForCategory: iconForCategory
            )
            
            // Product Info Section
            ProductInfoSection(
                product: product,
                isInCart: isInCart,
                cartItems: $cartItems,
                showingDetail: $showingDetail
            )
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(UIColor.quaternaryLabel), lineWidth: 0.5)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .onTapGesture {
            showingDetail = true
        }
        .onPressGesture(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
        .sheet(isPresented: $showingDetail) {
            ModernProductDetailSheet(product: product, cartItems: $cartItems)
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

// MARK: - Product Card Sub-Views
struct ProductImageSection: View {
    let product: Product
    let isInCart: Bool
    let iconForCategory: (Product.ProductCategory) -> String
    
    var body: some View {
        ZStack {
            AsyncImage(url: URL(string: product.imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure(let error):
                    // Show fallback when image fails to load
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: iconForCategory(product.category))
                                    .font(.system(size: 32))
                                    .foregroundStyle(.secondary)
                                Text("Image not available")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                Text("URL: \(product.imageURL)")
                                    .font(.caption2)
                                    .foregroundStyle(.quaternary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        )
                        .onAppear {
                            print("❌ Failed to load image for \(product.name): \(error.localizedDescription)")
                            print("🔗 Image URL: \(product.imageURL)")
                        }
                case .empty:
                    // Loading state
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            VStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Loading...")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        )
                        .onAppear {
                            print("📥 Loading image for \(product.name)")
                            print("🔗 Image URL: \(product.imageURL)")
                        }
                @unknown default:
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Image(systemName: iconForCategory(product.category))
                                .font(.system(size: 32))
                                .foregroundStyle(.secondary)
                        )
                }
            }
            .onAppear {
                print("✅ Product loaded: \(product.name)")
                print("🔗 Image URL: \(product.imageURL)")
            }
            .frame(height: 120)
            .clipped()
            
            // Stock status overlay
            VStack {
                HStack {
                    Spacer()
                    if !product.inStock {
                        Text("Out of Stock")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.red, in: Capsule())
                    } else if isInCart {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.green)
                            .background(.white, in: Circle())
                    }
                }
                Spacer()
            }
            .padding(12)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct ProductInfoSection: View {
    let product: Product
    let isInCart: Bool
    @Binding var cartItems: [Product]
    @Binding var showingDetail: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ProductHeaderInfo(product: product)
            ProductPriceSection(product: product)
            ProductActionButtons(
                product: product,
                isInCart: isInCart,
                cartItems: $cartItems,
                showingDetail: $showingDetail
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct ProductHeaderInfo: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Brand and Category
            HStack {
                if let brand = product.brand {
                    Text(brand)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                } else {
                    Text("Etell")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                }
                
                Spacer()
                
                Text(product.category.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            // Product Name
            Text(product.name)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Rating
            if let rating = product.rating {
                HStack(spacing: 4) {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundStyle(star <= Int(rating) ? .orange : .secondary.opacity(0.3))
                        }
                    }
                    
                    Text("\(rating, specifier: "%.1f")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct ProductPriceSection: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .bottom, spacing: 6) {
                Text("$\(product.price, specifier: "%.0f")")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                if let originalPrice = product.originalPrice, originalPrice > product.price {
                    Text("$\(originalPrice, specifier: "%.0f")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .strikethrough()
                }
            }
            
            if let stockCount = product.stockCount, stockCount > 0 && stockCount <= 5 {
                Text("Only \(stockCount) left")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .fontWeight(.medium)
            }
        }
    }
}

struct ProductActionButtons: View {
    let product: Product
    let isInCart: Bool
    @Binding var cartItems: [Product]
    @Binding var showingDetail: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            // Details Button
            Button {
                showingDetail = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                    Text("Details")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            }
            
            // Cart Button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if isInCart {
                        cartItems.removeAll { $0.id == product.id }
                    } else {
                        cartItems.append(product)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isInCart ? "checkmark" : "plus")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(isInCart ? "Added" : "Add")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: isInCart ? [.green, .green.opacity(0.8)] : [.blue, .blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 8)
                )
            }
            .disabled(!product.inStock && !isInCart)
        }
    }
}

struct ModernProductDetailSheet: View {
    let product: Product
    @Binding var cartItems: [Product]
    @Environment(\.dismiss) var dismiss
    
    var isInCart: Bool {
        cartItems.contains { $0.id == product.id }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Image Section
                    AsyncImage(url: URL(string: product.imageURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        case .failure(_):
                            // Show fallback when image fails to load
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    VStack(spacing: 12) {
                                        Image(systemName: iconForCategory(product.category))
                                            .font(.system(size: 60))
                                            .foregroundStyle(.secondary)
                                        Text("Image not available")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                )
                        case .empty:
                            // Loading state
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    VStack(spacing: 12) {
                                        ProgressView()
                                        Text("Loading image...")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                )
                        @unknown default:
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    Image(systemName: iconForCategory(product.category))
                                        .font(.system(size: 60))
                                        .foregroundStyle(.secondary)
                                )
                        }
                    }
                    .frame(maxHeight: 280)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    
                    // Product Information
                    VStack(alignment: .leading, spacing: 20) {
                        // Header Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    if let brand = product.brand {
                                        Text(brand)
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.blue)
                                    }
                                    
                                    Text(product.name)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.primary)
                                }
                                
                                Spacer()
                                
                                Text(product.category.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.blue.opacity(0.1), in: Capsule())
                            }
                            
                            // Rating and Reviews
                            if let rating = product.rating {
                                HStack(spacing: 12) {
                                    HStack(spacing: 4) {
                                        ForEach(1...5, id: \.self) { star in
                                            Image(systemName: star <= Int(rating) ? "star.fill" : "star")
                                                .font(.subheadline)
                                                .foregroundStyle(star <= Int(rating) ? .orange : .secondary.opacity(0.3))
                                        }
                                    }
                                    
                                    Text("\(rating, specifier: "%.1f")")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    
                                    Text("•")
                                        .foregroundStyle(.secondary)
                                    
                                    Text("4.2k reviews")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        // Description
                        Text(product.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                        
                        // Features/Tags
                        if let tags = product.tags, !tags.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Key Features")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                    ForEach(tags, id: \.self) { tag in
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.caption)
                                                .foregroundStyle(.green)
                                            
                                            Text(tag)
                                                .font(.subheadline)
                                                .foregroundStyle(.primary)
                                            
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Specifications
                        ModernSpecificationsSection(product: product)
                        
                        // Price and Stock Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Pricing & Availability")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .bottom, spacing: 12) {
                                        Text("$\(product.price, specifier: "%.0f")")
                                            .font(.title)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.primary)
                                        
                                        if let originalPrice = product.originalPrice, originalPrice > product.price {
                                            VStack(alignment: .leading) {
                                                Text("$\(originalPrice, specifier: "%.0f")")
                                                    .font(.title3)
                                                    .foregroundStyle(.secondary)
                                                    .strikethrough()
                                                
                                                Text("Save $\(Int(originalPrice - product.price))")
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundStyle(.green)
                                            }
                                        }
                                    }
                                    
                                    if let stockCount = product.stockCount, stockCount > 0 {
                                        if stockCount <= 5 {
                                            Text("Only \(stockCount) left in stock")
                                                .font(.subheadline)
                                                .foregroundStyle(.orange)
                                                .fontWeight(.medium)
                                        } else {
                                            Text("\(stockCount) units available")
                                                .font(.subheadline)
                                                .foregroundStyle(.green)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                // Stock Status Badge
                                HStack(spacing: 8) {
                                    Image(systemName: product.inStock ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundStyle(product.inStock ? .green : .red)
                                    
                                    Text(product.inStock ? "In Stock" : "Out of Stock")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(product.inStock ? .green : .red)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    (product.inStock ? Color.green : Color.red).opacity(0.1),
                                    in: Capsule()
                                )
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // Space for bottom button
            }
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Floating Add to Cart Button
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Total")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("$\(product.price, specifier: "%.0f")")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                        }
                        
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if isInCart {
                                    cartItems.removeAll { $0.id == product.id }
                                } else {
                                    cartItems.append(product)
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isInCart ? "checkmark" : "bag.badge.plus")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text(isInCart ? "Remove from Cart" : "Add to Cart")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: isInCart ? [.red, .red.opacity(0.8)] : [.blue, .blue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                        }
                        .disabled(!product.inStock && !isInCart)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(.ultraThinMaterial)
                }
            }
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

// MARK: - Product Detail Sub-Views  
struct ProductDetailFloatingButton: View {
    let product: Product
    let isInCart: Bool
    @Binding var cartItems: [Product]
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("$\(product.price, specifier: "%.0f")")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        if isInCart {
                            cartItems.removeAll { $0.id == product.id }
                        } else {
                            cartItems.append(product)
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isInCart ? "checkmark" : "bag.badge.plus")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text(isInCart ? "Remove from Cart" : "Add to Cart")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: isInCart ? [.red, .red.opacity(0.8)] : [.blue, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
                .disabled(!product.inStock && !isInCart)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
        }
    }
}

struct ModernSpecificationsSection: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Technical Specifications")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                if let specifications = product.specifications, !specifications.isEmpty {
                    ForEach(specifications.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        ModernSpecificationRow(title: key, value: value)
                    }
                } else {
                    // Default specifications
                    ForEach(defaultSpecifications, id: \.title) { spec in
                        ModernSpecificationRow(title: spec.title, value: spec.value)
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var defaultSpecifications: [(title: String, value: String)] {
        var specs = [
            ("Brand", product.brand ?? "Etell"),
            ("Warranty", "2 years international"),
            ("Compatibility", "Universal")
        ]
        
        if product.category == .router {
            specs.append(contentsOf: [
                ("WiFi Standard", "WiFi 6 (802.11ax)"),
                ("Max Speed", "Up to 1200 Mbps"),
                ("Coverage", "Up to 3000 sq ft"),
                ("Antennas", "4 x high-gain antennas")
            ])
        } else if product.category == .extender {
            specs.append(contentsOf: [
                ("Range Extension", "Up to 1500 sq ft"),
                ("Compatibility", "Works with any router"),
                ("Setup", "One-touch WPS setup")
            ])
        }
        
        return specs
    }
}

struct ModernSpecificationRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct ModernCartView: View {
    @Binding var items: [Product]
    @Environment(\.dismiss) var dismiss
    @State private var showingCheckout = false
    
    var totalPrice: Double {
        items.reduce(0) { $0 + $1.price }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if items.isEmpty {
                    // Empty Cart State
                    VStack(spacing: 24) {
                        VStack(spacing: 16) {
                            Image(systemName: "bag")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                            
                            VStack(spacing: 8) {
                                Text("Your Cart is Empty")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                
                                Text("Add products to your cart to get started")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("Continue Shopping")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Cart with Items
                    VStack(spacing: 0) {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(items) { item in
                                    ModernCartItemRow(product: item) {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            items.removeAll { $0.id == item.id }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 120) // Space for checkout section
                        }
                        
                        // Floating Checkout Section
                        VStack(spacing: 0) {
                            Divider()
                            
                            VStack(spacing: 16) {
                                // Price Summary
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("Subtotal (\(items.count) item\(items.count == 1 ? "" : "s"))")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        
                                        Spacer()
                                        
                                        Text("$\(totalPrice, specifier: "%.2f")")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.primary)
                                    }
                                    
                                    HStack {
                                        Text("Shipping")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                        
                                        Spacer()
                                        
                                        Text("Free")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.green)
                                    }
                                    
                                    Divider()
                                    
                                    HStack {
                                        Text("Total")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.primary)
                                        
                                        Spacer()
                                        
                                        Text("$\(totalPrice, specifier: "%.2f")")
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.blue)
                                    }
                                }
                                
                                // Checkout Button
                                Button {
                                    showingCheckout = true
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "creditcard")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        
                                        Text("Proceed to Checkout")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 16)
                            .background(.ultraThinMaterial)
                        }
                    }
                }
            }
            .navigationTitle("Cart")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
        .sheet(isPresented: $showingCheckout) {
            ModernCheckoutView(cartItems: $items, totalPrice: totalPrice) {
                // On checkout completion
                items.removeAll()
                showingCheckout = false
                dismiss()
            }
        }
    }
}

struct ModernCartItemRow: View {
    let product: Product
    let onRemove: () -> Void
    @State private var showingRemoveConfirmation = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Product Image
            AsyncImage(url: URL(string: product.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Image(systemName: iconForCategory(product.category))
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    )
            }
            .frame(width: 80, height: 80)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            
            // Product Details
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        if let brand = product.brand {
                            Text(brand)
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                        
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(product.category.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                HStack {
                    Text("$\(product.price, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                    
                    Spacer()
                    
                    Button {
                        showingRemoveConfirmation = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.caption)
                            Text("Remove")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.red.opacity(0.1), in: Capsule())
                    }
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(UIColor.quaternaryLabel), lineWidth: 0.5)
        )
        .confirmationDialog("Remove Item", isPresented: $showingRemoveConfirmation) {
            Button("Remove from Cart", role: .destructive) {
                onRemove()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to remove \(product.name) from your cart?")
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

// MARK: - Checkout View
struct ModernCheckoutView: View {
    @Binding var cartItems: [Product]
    let totalPrice: Double
    let onCompletion: () -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var selectedPaymentMethod = PaymentMethod.card
    @State private var cardNumber = ""
    @State private var expiryDate = ""
    @State private var cvv = ""
    @State private var fullName = ""
    @State private var email = ""
    @State private var address = ""
    @State private var city = ""
    @State private var zipCode = ""
    @State private var isProcessing = false
    @State private var showingSuccess = false
    
    enum PaymentMethod: String, CaseIterable {
        case card = "Credit Card"
        case paypal = "PayPal"
        case applePay = "Apple Pay"
        
        var icon: String {
            switch self {
            case .card: return "creditcard"
            case .paypal: return "p.circle"
            case .applePay: return "applelogo"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Order Summary
                    ModernOrderSummarySection(items: cartItems, total: totalPrice)
                    
                    // Payment Method Selection
                    ModernPaymentMethodSection(selectedMethod: $selectedPaymentMethod)
                    
                    // Payment Details
                    if selectedPaymentMethod == .card {
                        ModernPaymentDetailsSection(
                            cardNumber: $cardNumber,
                            expiryDate: $expiryDate,
                            cvv: $cvv
                        )
                    }
                    
                    // Billing Information
                    ModernBillingInfoSection(
                        fullName: $fullName,
                        email: $email,
                        address: $address,
                        city: $city,
                        zipCode: $zipCode
                    )
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 120) // Space for checkout button
            }
            .background(Color(.systemGroupedBackground))
            .overlay(alignment: .bottom) {
                // Floating Checkout Button
                VStack(spacing: 0) {
                    Divider()
                    
                    VStack(spacing: 16) {
                        HStack {
                            Text("Total")
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Text("$\(totalPrice, specifier: "%.2f")")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.blue)
                        }
                        
                        Button {
                            processPayment()
                        } label: {
                            HStack(spacing: 8) {
                                if isProcessing {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "lock.shield")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                
                                Text(isProcessing ? "Processing..." : "Complete Order")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: isProcessing ? [.gray, .gray.opacity(0.8)] : [.green, .green.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                        }
                        .disabled(isProcessing || !isFormValid)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("Checkout")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
        .alert("Order Successful!", isPresented: $showingSuccess) {
            Button("Continue Shopping") {
                onCompletion()
            }
        } message: {
            Text("Thank you for your order! You'll receive a confirmation email shortly.")
        }
    }
    
    private var isFormValid: Bool {
        !fullName.isEmpty && !email.isEmpty && 
        (selectedPaymentMethod != .card || (!cardNumber.isEmpty && !expiryDate.isEmpty && !cvv.isEmpty))
    }
    
    private func processPayment() {
        isProcessing = true
        
        // Save order to Firebase
        Task {
            await saveOrderToFirebase()
        }
    }
    
    private func saveOrderToFirebase() async {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ No authenticated user found")
            DispatchQueue.main.async {
                self.isProcessing = false
            }
            return
        }
        
        let billingInfo = BillingInfo(
            fullName: fullName,
            email: email,
            address: address,
            city: city,
            zipCode: zipCode
        )
        
        let order = Order(
            userId: currentUser.uid,
            items: cartItems,
            paymentMethod: selectedPaymentMethod.rawValue,
            billingInfo: billingInfo
        )
        
        do {
            let db = Firestore.firestore()
            let orderData = order.toFirestoreData()
            
            try await db.collection("users")
                .document(currentUser.uid)
                .collection("orders")
                .document(order.id)
                .setData(orderData)
            
            print("✅ Order saved successfully: \(order.id)")
            
            DispatchQueue.main.async {
                self.isProcessing = false
                self.showingSuccess = true
            }
        } catch {
            print("❌ Error saving order: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.isProcessing = false
            }
        }
    }
}

struct ModernOrderSummarySection: View {
    let items: [Product]
    let total: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Order Summary")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            VStack(spacing: 12) {
                ForEach(items.prefix(3)) { item in
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: item.imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.ultraThinMaterial)
                        }
                        .frame(width: 40, height: 40)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(1)
                            
                            Text(item.category.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("$\(item.price, specifier: "%.2f")")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                }
                
                if items.count > 3 {
                    Text("and \(items.count - 3) more item\(items.count - 3 == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Divider()
                
                HStack {
                    Text("Total (\(items.count) item\(items.count == 1 ? "" : "s"))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("$\(total, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(UIColor.quaternaryLabel), lineWidth: 0.5)
        )
    }
}

struct ModernPaymentMethodSection: View {
    @Binding var selectedMethod: ModernCheckoutView.PaymentMethod
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payment Method")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            VStack(spacing: 8) {
                ForEach(ModernCheckoutView.PaymentMethod.allCases, id: \.self) { method in
                    PaymentMethodButton(
                        method: method,
                        isSelected: selectedMethod == method,
                        onSelect: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedMethod = method
                            }
                        }
                    )
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(UIColor.quaternaryLabel), lineWidth: 0.5)
        )
    }
}

struct PaymentMethodButton: View {
    let method: ModernCheckoutView.PaymentMethod
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: method.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .frame(width: 24)
                
                Text(method.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                PaymentMethodSelectionIndicator(isSelected: isSelected)
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .background(
                isSelected ? .blue.opacity(0.1) : .clear,
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? .blue : Color(UIColor.quaternaryLabel),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PaymentMethodSelectionIndicator: View {
    let isSelected: Bool
    
    var body: some View {
        if isSelected {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.blue)
        } else {
            Circle()
                .stroke(Color(UIColor.quaternaryLabel), lineWidth: 1)
                .frame(width: 20, height: 20)
        }
    }
}

struct ModernPaymentDetailsSection: View {
    @Binding var cardNumber: String
    @Binding var expiryDate: String
    @Binding var cvv: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Card Details")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            VStack(spacing: 16) {
                ModernTextField(
                    title: "Card Number",
                    text: $cardNumber,
                    placeholder: "1234 5678 9012 3456",
                    icon: "creditcard"
                )
                
                HStack(spacing: 16) {
                    ModernTextField(
                        title: "Expiry Date",
                        text: $expiryDate,
                        placeholder: "MM/YY",
                        icon: "calendar"
                    )
                    
                    ModernTextField(
                        title: "CVV",
                        text: $cvv,
                        placeholder: "123",
                        icon: "lock.shield"
                    )
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(UIColor.quaternaryLabel), lineWidth: 0.5)
        )
    }
}

struct ModernBillingInfoSection: View {
    @Binding var fullName: String
    @Binding var email: String
    @Binding var address: String
    @Binding var city: String
    @Binding var zipCode: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Billing Information")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            VStack(spacing: 16) {
                ModernTextField(
                    title: "Full Name",
                    text: $fullName,
                    placeholder: "John Doe",
                    icon: "person"
                )
                
                ModernTextField(
                    title: "Email",
                    text: $email,
                    placeholder: "john@example.com",
                    icon: "envelope"
                )
                
                ModernTextField(
                    title: "Address",
                    text: $address,
                    placeholder: "123 Main Street",
                    icon: "location"
                )
                
                HStack(spacing: 16) {
                    ModernTextField(
                        title: "City",
                        text: $city,
                        placeholder: "New York",
                        icon: "building.2"
                    )
                    
                    ModernTextField(
                        title: "ZIP Code",
                        text: $zipCode,
                        placeholder: "10001",
                        icon: "number"
                    )
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(UIColor.quaternaryLabel), lineWidth: 0.5)
        )
    }
}

struct ModernTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                
                TextField(placeholder, text: $text)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(UIColor.quaternaryLabel), lineWidth: 0.5)
            )
        }
    }
}

#Preview {
    AccessoriesStoreView()
}
