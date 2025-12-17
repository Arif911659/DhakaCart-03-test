# DhakaCart Public API + Frontend Components Documentation

> Publish-ready reference for Medium/LinkedIn.
>
> **Last updated:** 2025-12-17

---

## Why this document exists (বাংলায়)
DhakaCart একটি cloud-native e-commerce platform। এই ডকুমেন্টে অ্যাপ্লিকেশনের **সব public REST API**, **frontend public React components**, এবং তাদের **usage examples** এক জায়গায় রাখা হয়েছে—যাতে আপনি Medium/LinkedIn এ প্রজেক্টটা সহজে explain করতে পারেন এবং অন্যরা দ্রুত ব্যবহার/ইন্টিগ্রেট করতে পারে।

---

## System context (very short)
- **Frontend**: React 18 (Nginx reverse proxy in production)
- **Backend**: Node.js 18 + Express
- **Database**: PostgreSQL (products, orders, order_items)
- **Cache**: Redis (product caching)

---

## Environments & Base URLs

### Local (dev)
- **Backend**: `http://localhost:5000`
- **API base**: `http://localhost:5000/api`
- **Health**: `http://localhost:5000/health`
- **Frontend**: `http://localhost:3000`

### Docker Compose (local stack)
`docker-compose.yml` starts:
- Frontend: `http://localhost:3000`
- Backend API: `http://localhost:5000/api`
- Backend health: `http://localhost:5000/health`

### Kubernetes (production-style)
Frontend Nginx proxies API calls:
- Frontend makes requests to a **relative** `/api/*`
- Nginx routes `/api/` to the backend service (`frontend/nginx.conf`)

---

## Cross-cutting behavior (applies to most endpoints)

### CORS
Backend allows:
- **Origin**: `CORS_ORIGIN` (default `http://localhost:3000`)
- **Methods**: `GET`, `POST`, `OPTIONS`
- **Allowed headers**: `Content-Type`, `x-api-key`

### Security headers
Backend uses `helmet()`.

### Rate limiting
All `/api/*` routes are rate-limited:
- **Window**: 15 minutes
- **Max**: 100 requests per IP per window

### Response conventions
- Most successful responses return JSON.
- Error responses usually return `{ "error": "..." }`.

---

## Public REST API Reference (Backend)

### 1) Health

#### `GET /health`
#### `GET /api/health`
**Purpose**: Health probe for load balancers and deployments. Checks DB + Redis.

**Success (HTTP 200)**:
```json
{
  "status": "OK",
  "timestamp": "2025-12-17T12:34:56.789Z",
  "services": {
    "database": "up",
    "redis": "up"
  }
}
```

**Degraded (HTTP 503)**: if DB or Redis check fails
```json
{
  "status": "DEGRADED",
  "timestamp": "2025-12-17T12:34:56.789Z",
  "services": {
    "database": "down",
    "redis": "up"
  }
}
```

**curl**:
```bash
curl -sS http://localhost:5000/health | jq
curl -sS http://localhost:5000/api/health | jq
```

---

### 2) Products

#### `GET /api/products`
**Purpose**: List all products.

**Caching**:
- Redis key: `products:all`
- TTL: 300 seconds
- Response includes `source: "cache" | "database"`

**Success (HTTP 200)**:
```json
{
  "source": "cache",
  "data": [
    {
      "id": 1,
      "name": "Samsung Galaxy A54",
      "description": "Latest Samsung smartphone with 128GB storage",
      "price": 35990,
      "category": "Electronics",
      "stock": 50,
      "image_url": "https://...",
      "created_at": "2025-12-17T...",
      "updated_at": "2025-12-17T..."
    }
  ]
}
```

**Error (HTTP 500)**:
```json
{ "error": "Failed to fetch products" }
```

**curl**:
```bash
curl -sS http://localhost:5000/api/products | jq
```

#### `GET /api/products/:id`
**Purpose**: Fetch a single product by ID.

**Caching**:
- Redis key: `product:<id>`
- TTL: 300 seconds
- Response includes `source: "cache" | "database"`

**Success (HTTP 200)**:
```json
{
  "source": "database",
  "data": {
    "id": 1,
    "name": "Samsung Galaxy A54",
    "price": 35990,
    "stock": 50
  }
}
```

**Not found (HTTP 404)**:
```json
{ "error": "Product not found" }
```

**curl**:
```bash
curl -sS http://localhost:5000/api/products/1 | jq
```

#### `GET /api/products/category/:category`
**Purpose**: List products for a specific category.

**Success (HTTP 200)**:
```json
{
  "data": [
    {
      "id": 4,
      "category": "Clothing",
      "price": 2500,
      "stock": 100
    }
  ]
}
```

**curl**:
```bash
curl -sS http://localhost:5000/api/products/category/Electronics | jq
```

---

### 3) Categories

#### `GET /api/categories`
**Purpose**: List distinct product categories.

**Success (HTTP 200)**:
```json
{ "data": ["Beverages", "Books", "Clothing", "Electronics"] }
```

**curl**:
```bash
curl -sS http://localhost:5000/api/categories | jq
```

---

### 4) Orders

#### `POST /api/orders`
**Purpose**: Place a new order.

**What the server guarantees**
- Validates request shape with Joi.
- Computes total from items and rejects mismatch.
- Runs a PostgreSQL **transaction**.
- Locks product rows (`FOR UPDATE`) to prevent race conditions.
- Verifies stock, inserts order + items, updates stock.
- Clears Redis key `products:all` after successful order to refresh catalog.

**Request body (required)**
```json
{
  "customer_name": "Rahim Ahmed",
  "customer_email": "rahim@example.com",
  "customer_phone": "01712345678",
  "delivery_address": "Mirpur-10, Dhaka",
  "total_amount": 38500,
  "items": [
    {
      "product_id": 1,
      "quantity": 1,
      "price": 35990
    },
    {
      "product_id": 4,
      "quantity": 1,
      "price": 2500
    }
  ]
}
```

**Success (HTTP 201)**
```json
{
  "message": "Order placed successfully",
  "order": {
    "id": 2,
    "customer_name": "Rahim Ahmed",
    "customer_email": "rahim@example.com",
    "customer_phone": "01712345678",
    "delivery_address": "Mirpur-10, Dhaka",
    "total_amount": 38500,
    "status": "pending",
    "created_at": "2025-12-17T...",
    "updated_at": "2025-12-17T..."
  }
}
```

**Validation error (HTTP 400)**
```json
{
  "error": "Invalid order payload",
  "details": [
    "\"customer_email\" must be a valid email",
    "\"items\" must contain at least 1 items"
  ]
}
```

**Business error examples (HTTP 400)**
- Total mismatch:
```json
{ "error": "Total amount mismatch" }
```

- Product not found / insufficient stock:
```json
{ "error": "Insufficient stock for product 1. Available: 2, requested: 10" }
```

**Server error (HTTP 500)**
```json
{ "error": "Failed to create order" }
```

**curl**:
```bash
curl -sS -X POST http://localhost:5000/api/orders \
  -H 'Content-Type: application/json' \
  -d '{
    "customer_name": "Rahim Ahmed",
    "customer_email": "rahim@example.com",
    "customer_phone": "01712345678",
    "delivery_address": "Mirpur-10, Dhaka",
    "total_amount": 38500,
    "items": [
      {"product_id": 1, "quantity": 1, "price": 35990},
      {"product_id": 4, "quantity": 1, "price": 2500}
    ]
  }' | jq
```

#### `GET /api/orders/:id`
**Purpose**: Fetch order details + line items.

**Success (HTTP 200)**
```json
{
  "order": {
    "id": 1,
    "customer_name": "...",
    "total_amount": "38500.00",
    "status": "delivered"
  },
  "items": [
    {
      "id": 1,
      "order_id": 1,
      "product_id": 1,
      "quantity": 1,
      "price": "35990.00",
      "name": "Samsung Galaxy A54",
      "image_url": "https://..."
    }
  ]
}
```

> Note: Depending on `pg` settings, `DECIMAL` fields may come as strings (e.g., `"38500.00"`).

**Not found (HTTP 404)**
```json
{ "error": "Order not found" }
```

**curl**:
```bash
curl -sS http://localhost:5000/api/orders/1 | jq
```

---

### 5) Admin (Cache)

#### `POST /api/admin/clear-cache`
**Purpose**: Flush Redis cache (admin only).

**Auth**: Header `x-api-key: <ADMIN_API_KEY>`

**Server-side requirement**: `ADMIN_API_KEY` must be set on the backend.

**Success (HTTP 200)**
```json
{ "message": "Cache cleared successfully" }
```

**Unauthorized (HTTP 401)**
```json
{ "error": "Unauthorized" }
```

**Not configured (HTTP 503)**
```json
{ "error": "Admin API key not configured on server" }
```

**curl**:
```bash
curl -sS -X POST http://localhost:5000/api/admin/clear-cache \
  -H 'x-api-key: YOUR_ADMIN_API_KEY' | jq
```

---

## Frontend public components (React)

### Data shapes used across components

#### `Product`
```js
{
  id: number,
  name: string,
  description: string | null,
  price: number,
  category: string | null,
  stock: number,
  image_url: string
}
```

#### `CartItem`
Same as `Product` + `quantity: number`.

---

### `App` (`frontend/src/App.js`)
**Role**: Main application shell, state management, API integration.

**Key behaviors (publicly observable)**
- Chooses API base:
  - Uses `process.env.REACT_APP_API_URL` if set.
  - Defaults to **relative** `/api` (recommended for Nginx/K8s proxying).
- Loads:
  - `GET /api/products` → populates catalog
  - `GET /api/categories` → populates category filter
- Shopping cart rules:
  - Prevents adding items when `stock <= 0`.
  - Prevents quantity from exceeding available stock.
- Checkout:
  - Sends `POST /api/orders` with computed cart totals.
  - On success: clears cart, closes modal, refreshes product list to show updated stock.

**Usage**
`index.js` renders it as the root component:
```jsx
<React.StrictMode>
  <App />
</React.StrictMode>
```

---

### `Header` (`frontend/src/components/Header.js`)
**Props**
- `cart: CartItem[]`
- `toggleCart: () => void`

**What it does**
- Shows app title/tagline.
- Shows cart button with item counts:
  - `cart.length` (unique items)
  - `totalItems` badge (sum of quantities)

**Example**
```jsx
<Header cart={cart} toggleCart={() => setShowCart(v => !v)} />
```

---

### `ProductList` (`frontend/src/components/ProductList.js`)
**Props**
- `products: Product[]`
- `categories: string[]`
- `selectedCategory: string`
- `setSelectedCategory: (category: string) => void`
- `addToCart: (product: Product) => void`

**What it does**
- Category filter UI.
- Filters products client-side.
- Renders a grid of `ProductCard`.

**Example**
```jsx
<ProductList
  products={products}
  categories={categories}
  selectedCategory={selectedCategory}
  setSelectedCategory={setSelectedCategory}
  addToCart={addToCart}
/>
```

---

### `ProductCard` (`frontend/src/components/ProductCard.js`)
**Props**
- `product: Product`
- `addToCart: (product: Product) => void`

**What it does**
- Shows product image, description, price, and stock.
- Disables button when `stock === 0`.

**Example**
```jsx
<ProductCard product={product} addToCart={addToCart} />
```

---

### `CartSidebar` (`frontend/src/components/CartSidebar.js`)
**Props**
- `cart: CartItem[]`
- `onClose: () => void`
- `removeFromCart: (productId: number) => void`
- `updateQuantity: (productId: number, newQuantity: number) => void`
- `onCheckout: () => void`

**What it does**
- Renders cart items.
- Quantity controls call `updateQuantity`.
- Checkout button triggers `onCheckout`.

**Example**
```jsx
<CartSidebar
  cart={cart}
  onClose={() => setShowCart(false)}
  removeFromCart={removeFromCart}
  updateQuantity={updateQuantity}
  onCheckout={() => setShowCheckout(true)}
/>
```

---

### `CheckoutModal` (`frontend/src/components/CheckoutModal.js`)
**Props**
- `onClose: () => void`
- `cart: CartItem[]`
- `totalAmount: number`
- `onSubmit: (customerInfo: { name: string, email: string, phone: string, address: string }) => void`
- `error: string | null`

**What it does**
- Collects customer info.
- Shows order summary.
- Submits customer info to parent handler.

**Example**
```jsx
<CheckoutModal
  onClose={() => setShowCheckout(false)}
  cart={cart}
  totalAmount={getTotalAmount()}
  onSubmit={handleCheckout}
  error={checkoutError}
/>
```

---

## End-to-end usage (quick demo script)

### 1) Start everything locally
```bash
docker-compose up -d
```

### 2) Verify health
```bash
curl -sS http://localhost:5000/health | jq
```

### 3) List products and categories
```bash
curl -sS http://localhost:5000/api/products | jq
curl -sS http://localhost:5000/api/categories | jq
```

### 4) Place an order and verify stock updates
1) Create an order (see `POST /api/orders` curl above)
2) Fetch the order:
```bash
curl -sS http://localhost:5000/api/orders/2 | jq
```
3) Re-fetch products to see stock decrement:
```bash
curl -sS http://localhost:5000/api/products | jq
```

---

## Notes for writing a Medium/LinkedIn post
- **Story angle (বাংলায়)**: “একটা ছোট monolithic app কে production-ready cloud-native platform এ ট্রান্সফর্ম”
- **Show the contracts**: above API examples are copy/paste-friendly.
- **Highlight reliability**: health checks, rate limiting, DB transaction + row locks, Redis caching.
- **Demo**: short GIF/screenshot of `Product → Cart → Checkout → Order success` flow.
