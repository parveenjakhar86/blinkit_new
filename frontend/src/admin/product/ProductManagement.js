
import React, { useEffect, useMemo, useState } from "react";

const emptyForm = {
  name: "",
  category: "General",
  price: "",
  stock: "",
  description: "",
  image: ""
};

const formatINR = (value) =>
  new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    maximumFractionDigits: 0
  }).format(Number(value || 0));

function toDataUrl(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = () => reject(new Error("Failed to read image file"));
    reader.readAsDataURL(file);
  });
}

export default function ProductManagement() {
  const [products, setProducts] = useState([]);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [editProduct, setEditProduct] = useState(null);
  const [form, setForm] = useState(emptyForm);

  const token = localStorage.getItem("adminToken") || localStorage.getItem("managerToken");

  const fetchProducts = async () => {
    setLoading(true);
    setError("");
    try {
      const res = await fetch("/api/admin/products", {
        headers: {
          Authorization: `Bearer ${token}`
        }
      });
      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.message || "Failed to fetch products");
      }
      setProducts(data);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchProducts();
  }, []);

  const filteredProducts = useMemo(() => {
    const key = search.toLowerCase().trim();
    if (!key) return products;
    return products.filter(
      (product) =>
        product.name?.toLowerCase().includes(key) ||
        product.category?.toLowerCase().includes(key)
    );
  }, [products, search]);

  const openCreateModal = () => {
    setEditProduct(null);
    setForm(emptyForm);
    setShowForm(true);
  };

  const openEditModal = (product) => {
    setEditProduct(product);
    setForm({
      name: product.name || "",
      category: product.category || "General",
      price: String(product.price ?? ""),
      stock: String(product.stock ?? ""),
      description: product.description || "",
      image: product.image || ""
    });
    setShowForm(true);
  };

  const handleImageFileChange = async (event) => {
    const file = event.target.files && event.target.files[0];
    if (!file) return;
    try {
      const dataUrl = await toDataUrl(file);
      setForm((prev) => ({ ...prev, image: dataUrl }));
    } catch (err) {
      alert(err.message);
    }
  };

  const handleSubmit = async (event) => {
    event.preventDefault();
    setIsSubmitting(true);
    try {
      const method = editProduct ? "PUT" : "POST";
      const url = editProduct
        ? `/api/admin/products/${editProduct._id}`
        : "/api/admin/products";

      const payload = {
        name: form.name,
        category: form.category || "General",
        price: Number(form.price),
        stock: Number(form.stock || 0),
        description: form.description,
        image: form.image
      };

      const res = await fetch(url, {
        method,
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify(payload)
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.message || "Failed to save product");
      }

      if (editProduct) {
        setProducts((prev) => prev.map((item) => (item._id === data._id ? data : item)));
      } else {
        setProducts((prev) => [data, ...prev]);
      }

      setShowForm(false);
      setEditProduct(null);
      setForm(emptyForm);
    } catch (err) {
      alert(err.message);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDelete = async (productId) => {
    if (!window.confirm("Delete this product?")) return;
    try {
      const res = await fetch(`/api/admin/products/${productId}`, {
        method: "DELETE",
        headers: {
          Authorization: `Bearer ${token}`
        }
      });
      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.message || "Failed to delete product");
      }
      setProducts((prev) => prev.filter((item) => item._id !== productId));
    } catch (err) {
      alert(err.message);
    }
  };

  return (
    <div className="p-8 bg-gray-50 min-h-screen">
      <h2 className="text-2xl font-bold mb-6 text-gray-800">Product Management</h2>

      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-6 gap-4">
        <input
          type="text"
          placeholder="Search products by name or category..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="w-full sm:w-80 px-4 py-2 border rounded-lg focus:outline-none focus:ring"
        />
        <button
          onClick={openCreateModal}
          className="bg-yellow-600 text-white px-5 py-2 rounded-lg font-semibold shadow hover:bg-yellow-700 transition"
        >
          + Add Product
        </button>
      </div>

      <div className="bg-white rounded-xl shadow p-4 overflow-x-auto">
        {loading ? (
          <div className="text-gray-500">Loading products...</div>
        ) : error ? (
          <div className="text-red-500">{error}</div>
        ) : (
          <table className="min-w-full text-sm">
            <thead>
              <tr className="text-left text-gray-500 border-b">
                <th className="py-2 pr-4">Image</th>
                <th className="py-2 pr-4">Name</th>
                <th className="py-2 pr-4">Category</th>
                <th className="py-2 pr-4">Price</th>
                <th className="py-2 pr-4">Stock</th>
                <th className="py-2 pr-4">Status</th>
                <th className="py-2">Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredProducts.map((product) => (
                <tr key={product._id} className="border-b hover:bg-gray-50">
                  <td className="py-2 pr-4">
                    {product.image ? (
                      <img
                        src={product.image}
                        alt={product.name}
                        className="w-12 h-12 rounded object-cover border"
                      />
                    ) : (
                      <span className="text-gray-400">No image</span>
                    )}
                  </td>
                  <td className="py-2 pr-4 font-medium">{product.name}</td>
                  <td className="py-2 pr-4">{product.category || "General"}</td>
                  <td className="py-2 pr-4">{formatINR(product.price)}</td>
                  <td className="py-2 pr-4">{product.stock}</td>
                  <td className="py-2 pr-4">
                    <span
                      className={`px-2 py-1 rounded text-xs font-semibold ${
                        Number(product.stock) > 0
                          ? "bg-green-100 text-green-700"
                          : "bg-gray-200 text-gray-500"
                      }`}
                    >
                      {Number(product.stock) > 0 ? "Active" : "Inactive"}
                    </span>
                  </td>
                  <td className="py-2 flex gap-2">
                    <button
                      onClick={() => openEditModal(product)}
                      className="px-3 py-1 bg-blue-100 text-blue-700 rounded hover:bg-blue-200 transition"
                    >
                      Edit
                    </button>
                    <button
                      onClick={() => handleDelete(product._id)}
                      className="px-3 py-1 bg-red-100 text-red-700 rounded hover:bg-red-200 transition"
                    >
                      Delete
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>

      {showForm && (
        <div className="fixed inset-0 bg-black bg-opacity-30 flex items-center justify-center z-50 p-4">
          <form
            onSubmit={handleSubmit}
            className="bg-white w-full max-w-2xl rounded-xl shadow-xl p-6 space-y-4"
          >
            <h3 className="text-xl font-bold text-gray-800">
              {editProduct ? "Edit Product" : "Add Product"}
            </h3>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <input
                required
                type="text"
                placeholder="Product name"
                value={form.name}
                onChange={(e) => setForm((prev) => ({ ...prev, name: e.target.value }))}
                className="px-3 py-2 border rounded"
              />
              <input
                type="text"
                placeholder="Category"
                value={form.category}
                onChange={(e) => setForm((prev) => ({ ...prev, category: e.target.value }))}
                className="px-3 py-2 border rounded"
              />
              <input
                required
                min="0"
                type="number"
                placeholder="Price"
                value={form.price}
                onChange={(e) => setForm((prev) => ({ ...prev, price: e.target.value }))}
                className="px-3 py-2 border rounded"
              />
              <input
                min="0"
                type="number"
                placeholder="Stock"
                value={form.stock}
                onChange={(e) => setForm((prev) => ({ ...prev, stock: e.target.value }))}
                className="px-3 py-2 border rounded"
              />
            </div>

            <textarea
              rows="3"
              placeholder="Description"
              value={form.description}
              onChange={(e) => setForm((prev) => ({ ...prev, description: e.target.value }))}
              className="w-full px-3 py-2 border rounded"
            />

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <input
                type="text"
                placeholder="Image URL (optional)"
                value={form.image}
                onChange={(e) => setForm((prev) => ({ ...prev, image: e.target.value }))}
                className="px-3 py-2 border rounded"
              />
              <input
                type="file"
                accept="image/*"
                onChange={handleImageFileChange}
                className="px-3 py-2 border rounded bg-white"
              />
            </div>

            {form.image && (
              <div>
                <div className="text-sm text-gray-500 mb-1">Image preview</div>
                <img
                  src={form.image}
                  alt="preview"
                  className="w-28 h-28 rounded border object-cover"
                />
              </div>
            )}

            <div className="flex justify-end gap-2 pt-2">
              <button
                type="button"
                onClick={() => {
                  setShowForm(false);
                  setEditProduct(null);
                }}
                className="px-4 py-2 rounded bg-gray-200 hover:bg-gray-300"
              >
                Cancel
              </button>
              <button
                disabled={isSubmitting}
                type="submit"
                className="px-4 py-2 rounded bg-yellow-600 text-white hover:bg-yellow-700 disabled:opacity-60"
              >
                {isSubmitting ? "Saving..." : editProduct ? "Update Product" : "Create Product"}
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}
