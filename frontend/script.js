/**
 * Secure File Share - Frontend Logic
 * Handles interaction between the browser, API Gateway, and S3.
 */

// ============================================================
// 1. INITIALIZATION (On Page Load)
// ============================================================

window.onload = function () {
  const params = new URLSearchParams(window.location.search);
  const fileIdFromUrl = params.get("file_id");

  // Auto-fill download input if user arrived via shared link
  if (fileIdFromUrl) {
    const input = document.getElementById("fileIdInput");
    if (input) {
      input.value = fileIdFromUrl;
      input.scrollIntoView({ behavior: "smooth" });
    }
  }
};

// ============================================================
// 2. UPLOAD LOGIC
// ============================================================

async function handleUpload() {
  const fileInput = document.getElementById("fileInput");
  const uploadBtn = document.getElementById("uploadBtn");
  const resultBox = document.getElementById("uploadResult");

  const file = fileInput.files[0];
  if (!file) {
    alert("Please select a file first!");
    return;
  }

  // 10mb size limit check (client-side)
  const MAX_FILE_SIZE_MB = 10; // Must match backend limit
  if (file.size > MAX_FILE_SIZE_MB * 1024 * 1024) {
    alert(`File exceeds maximum size of ${MAX_FILE_SIZE_MB} MB.`);
    return;
  }

  // Lock UI during upload
  uploadBtn.disabled = true;
  uploadBtn.innerText = "Uploading...";
  resultBox.classList.add("hidden");

  try {
    // --- STEP A: Request Upload Permission & Send Metadata ---
    console.log("Requesting upload link from API...");

    const response = await fetch(API_BASE_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      // We send the original filename and type to the Lambda
      // so it can be stored in DynamoDB for later retrieval.
      body: JSON.stringify({
        filename: file.name,
        content_type: file.type || "application/octet-stream",
        file_size: file.size,
      }),
    });
    if (!response.ok) {
      // Handle explicit errors from Lambda (like "File too large")
      const errData = await response.json();
      throw new Error(errData.message || `API Error: ${response.statusText}`);
    }

    const data = await response.json();
    console.log("Received Presigned URL");

    // --- STEP B: Direct Upload to S3 ---
    console.log("Uploading content directly to S3...");

    const uploadResponse = await fetch(data.upload_url, {
      method: "PUT",
      body: file,
      headers: {
        // Must match the content type signed by the Lambda
        "Content-Type": "application/octet-stream",
      },
    });

    if (!uploadResponse.ok) {
      throw new Error("Failed to upload file to storage bucket.");
    }

    // --- STEP C: Generate Shareable Link & Update UI ---
    const shareableLink = `${window.location.origin}${window.location.pathname}?file_id=${data.file_id}`;

    // We use a read-only input field for the link so users can see it easily.
    // The button triggers the 'copyToClipboard' function defined below.
    resultBox.innerHTML = `
        <div class="success">
            <strong>✅ Upload Successful!</strong><br>
            <p style="margin: 5px 0; font-size: 0.9em;">Share this link:</p>
            
            <div class="copy-wrapper">
                <input type="text" class="copy-input" value="${shareableLink}" readonly onclick="this.select();">
                <button class="copy-btn" onclick="copyToClipboard(this, '${shareableLink}')">📋 Copy</button>
            </div>
            
            <p style="font-size: 0.8em; color: #666; margin-top: 5px;">
                File ID: <b style="user-select: all;">${data.file_id}</b>
            </p>
        </div>
    `;
    resultBox.classList.remove("hidden");
  } catch (error) {
    console.error(error);
    resultBox.innerHTML = `<div class="error"><strong>❌ Error:</strong> ${error.message}</div>`;
    resultBox.classList.remove("hidden");
  } finally {
    uploadBtn.disabled = false;
    uploadBtn.innerText = "Generate Link";
  }
}

// ============================================================
// 3. DOWNLOAD LOGIC
// ============================================================

async function handleDownload() {
  const fileIdInput = document.getElementById("fileIdInput");
  const downloadBtn = document.getElementById("downloadBtn");
  const resultBox = document.getElementById("downloadResult");

  const fileId = fileIdInput.value.trim();

  if (!fileId) {
    alert("Please enter a File ID");
    return;
  }

  // UI Feedback
  downloadBtn.disabled = true;
  downloadBtn.innerText = "Checking...";
  resultBox.classList.add("hidden");

  try {
    console.log(`Requesting download link for ID: ${fileId}`);

    // Step A: Ask API for the download link (instead of navigating blindly)
    const response = await fetch(`${API_BASE_URL}?file_id=${fileId}`, {
      method: "GET",
      // Note: Even though we use GET, API Gateway might send POST to Lambda internally,
      // but that's transparent to us here.
    });

    const data = await response.json();

    // Step B: Check for errors (like 403 or 404)
    if (!response.ok) {
      throw new Error(data.message || `Error: ${response.statusText}`);
    }

    // Step C: Success! Navigate to the S3 URL
    console.log("Link received, starting download...");
    window.location.href = data.download_url;

    // Optional: clear the input after success
    fileIdInput.value = "";
  } catch (error) {
    console.error(error);
    // Step D: Show error inside the page (Red Box)
    resultBox.innerHTML = `
            <div class="error">
                <strong>❌ Download Failed:</strong><br>
                ${error.message}
            </div>
        `;
    resultBox.classList.remove("hidden");
  } finally {
    downloadBtn.disabled = false;
    downloadBtn.innerText = "Download File";
  }
}

// ============================================================
// 4. UTILITY: COPY TO CLIPBOARD
// ============================================================

/**
 * Copies text to the system clipboard and provides visual feedback.
 * @param {HTMLElement} btnElement - The button that was clicked
 * @param {string} textToCopy - The URL or text to copy
 */
async function copyToClipboard(btnElement, textToCopy) {
  try {
    // Use the modern Clipboard API
    await navigator.clipboard.writeText(textToCopy);

    // UI Feedback: Change button color and text
    const originalText = btnElement.innerText;
    btnElement.innerText = "Copied!";
    btnElement.classList.add("copy-success");

    // Revert back to original state after 2 seconds
    setTimeout(() => {
      btnElement.innerText = originalText;
      btnElement.classList.remove("copy-success");
    }, 2000);
  } catch (err) {
    console.error("Failed to copy: ", err);
    alert("Failed to copy link manually. Please select the text and copy.");
  }
}

