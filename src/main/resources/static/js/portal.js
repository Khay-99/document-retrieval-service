/**
 * Thin client for the /api/documents endpoints exposed by DocumentController.
 * No framework, no build step - this is a reference UI, kept deliberately
 * simple so a candidate can read the whole flow in one file.
 */
(function () {
    const clientRefInput = document.getElementById("clientRef");
    const loadDocsBtn = document.getElementById("loadDocsBtn");
    const uploadForm = document.getElementById("uploadForm");
    const fileInput = document.getElementById("fileInput");
    const uploadStatus = document.getElementById("uploadStatus");
    const docsTableBody = document.getElementById("docsTableBody");

    function currentClientRef() {
        return clientRefInput.value.trim();
    }

    function setStatus(el, message, kind) {
        el.textContent = message;
        el.className = "status" + (kind ? " " + kind : "");
    }

    function formatBytes(bytes) {
        if (bytes < 1024) return bytes + " B";
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB";
        return (bytes / (1024 * 1024)).toFixed(1) + " MB";
    }

    async function loadDocuments() {
        const clientRef = currentClientRef();
        if (!clientRef) {
            alert("Enter a client reference first.");
            return;
        }

        docsTableBody.innerHTML = '<tr><td colspan="4" class="empty">Loading...</td></tr>';

        try {
            const response = await fetch(`/api/documents/${encodeURIComponent(clientRef)}`);
            if (!response.ok) {
                throw new Error(`Server returned ${response.status}`);
            }
            const documents = await response.json();
            renderDocuments(clientRef, documents);
        } catch (err) {
            docsTableBody.innerHTML = `<tr><td colspan="4" class="empty">Could not load documents: ${err.message}</td></tr>`;
        }
    }

    function renderDocuments(clientRef, documents) {
        if (!documents.length) {
            docsTableBody.innerHTML = '<tr><td colspan="4" class="empty">No documents on file for this reference yet.</td></tr>';
            return;
        }

        docsTableBody.innerHTML = "";
        documents.forEach((doc) => {
            const row = document.createElement("tr");

            const nameCell = document.createElement("td");
            nameCell.textContent = doc.filename;

            const sizeCell = document.createElement("td");
            sizeCell.textContent = formatBytes(doc.sizeBytes);

            const dateCell = document.createElement("td");
            dateCell.textContent = new Date(doc.lastModified).toLocaleString();

            const linkCell = document.createElement("td");
            const link = document.createElement("a");
            link.className = "doc-link";
            link.href = `/api/documents/${encodeURIComponent(clientRef)}/${encodeURIComponent(doc.filename)}`;
            link.textContent = "View / download";
            link.target = "_blank";
            linkCell.appendChild(link);

            row.append(nameCell, sizeCell, dateCell, linkCell);
            docsTableBody.appendChild(row);
        });
    }

    async function uploadDocument(event) {
        event.preventDefault();

        const clientRef = currentClientRef();
        if (!clientRef) {
            alert("Enter a client reference before uploading.");
            return;
        }
        if (!fileInput.files.length) {
            return;
        }

        const file = fileInput.files[0];
        const formData = new FormData();
        formData.append("file", file);

        setStatus(uploadStatus, "Uploading...", "");

        try {
            const response = await fetch(
                `/api/documents/${encodeURIComponent(clientRef)}/${encodeURIComponent(file.name)}`,
                { method: "PUT", body: formData }
            );

            if (!response.ok) {
                const detail = await response.text();
                throw new Error(detail || `Server returned ${response.status}`);
            }

            setStatus(uploadStatus, `Uploaded "${file.name}".`, "ok");
            uploadForm.reset();
            loadDocuments();
        } catch (err) {
            setStatus(uploadStatus, `Upload failed: ${err.message}`, "error");
        }
    }

    loadDocsBtn.addEventListener("click", loadDocuments);
    uploadForm.addEventListener("submit", uploadDocument);
})();
