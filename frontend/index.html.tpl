<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Secure One-Time File Share</title>

    <link rel="stylesheet" href="style.css">
</head>
<body>

    <div class="container">
        
        <header>
            <h1>🔒 Secure File Share</h1>
            <p class="subtitle">Upload securely, share instantly, disappear automatically.</p>
        </header>

        <section class="card upload-section">
            <h2>1. Upload File</h2>
            
            <div class="form-group">
                <input type="file" id="fileInput">
            </div>

            <div class="form-group">
                <button id="uploadBtn" onclick="handleUpload()">Generate Link</button>
            </div>

            <div id="uploadResult" class="result-box hidden"></div>
        </section>

        <div class="divider">OR</div>

        <section class="card download-section">
            <h2>2. Download File</h2>
            
            <div class="form-group">
                <input type="text" id="fileIdInput" placeholder="Paste File ID here...">
            </div>

            <div class="form-group">
                <button id="downloadBtn" class="secondary-btn" onclick="handleDownload()">Download File</button>
            </div>

            <div id="downloadResult" class="result-box hidden"></div>
        </section>

    </div>

    <script>
        // ============================================================
        // CONFIGURATION (Injected by Terraform)
        // ============================================================
        
        // Terraform's 'templatefile' function will replace ${api_url} 
        // with the actual API Gateway URL during the 'terraform apply' process.
        const API_BASE_URL = "${api_url}"; 
    </script>
    
    <script src="script.js"></script>

</body>
</html>
