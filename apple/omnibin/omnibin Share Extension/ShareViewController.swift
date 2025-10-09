import UIKit
import Foundation
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    
    private var isProcessing = false
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private let statusLabel = UILabel()
    private let cancelButton = UIButton(type: .system)

    // Header
    private let headerContainer = UIView()
    private let closeButton = UIButton(type: .system)
    private let addButton = UIButton(type: .system)
    private let titleStack = UIStackView()
    private let logoImageView = UIImageView()
    private let titleLabel = UILabel()

    // Content container (drawer style)
    private let drawerContainer = UIView()
    private let previewContainer = UIView()
    private let previewImageView = UIImageView()
    private let previewTextView = UITextView()
    private let bottomLogoImageView = UIImageView()
    
    // URL Preview UI elements
    private let urlPreviewContainer = UIView()
    private let urlPreviewImageView = UIImageView()
    private let urlPreviewTitleLabel = UILabel()
    private let urlPreviewDescriptionLabel = UILabel()
    private let urlPreviewSiteLabel = UILabel()
    private let urlPreviewIconImageView = UIImageView()
    private let statusStack = UIStackView()
    private let countLabel = UILabel()
    private let warningLabel = UILabel()
    private var imageBottomConstraint: NSLayoutConstraint?
    private var textBottomConstraint: NSLayoutConstraint?
    private var imageAspectConstraint: NSLayoutConstraint?
    private var textPreviewMaxHeightConstraint: NSLayoutConstraint?
    private var previewTextHeightConstraint: NSLayoutConstraint?
    private var imagePreviewMaxHeightConstraint: NSLayoutConstraint?
    private var limitWarningText: String?
    private let binItemsLimit = 10
    
    // URL Preview properties
    private var ogData: OGData?
    private var isOGLoading = false
    private var titleLeadingConstraint: NSLayoutConstraint?
    
    private enum SharedContent {
        case text(String)
        case url(URL)
        case image(UIImage)
        case fileURL(URL)
    }
    private var sharedContent: SharedContent?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadSharedContentForPreview()
        Task { await self.checkAndShowBinLimitWarning() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !previewTextView.isHidden {
            adjustTextHeightToContent()
        }
    }
    
    
    
    private func setupUI() {
        view.backgroundColor = UIColor.systemGroupedBackground

        // Drawer container styling
        drawerContainer.translatesAutoresizingMaskIntoConstraints = false
        drawerContainer.backgroundColor = UIColor.systemBackground
        drawerContainer.layer.cornerRadius = 16
        drawerContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        drawerContainer.layer.masksToBounds = true
        view.addSubview(drawerContainer)

        // Header
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.backgroundColor = UIColor.secondarySystemBackground
        drawerContainer.addSubview(headerContainer)

        // Close button (X)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        let closeConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        closeButton.setImage(UIImage(systemName: "xmark", withConfiguration: closeConfig), for: .normal)
        closeButton.tintColor = UIColor.label
        closeButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        headerContainer.addSubview(closeButton)

        // Add button
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.setTitle("Add", for: .normal)
        addButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        addButton.addTarget(self, action: #selector(addTapped), for: .touchUpInside)
        headerContainer.addSubview(addButton)

        // Title + logo
        titleStack.translatesAutoresizingMaskIntoConstraints = false
        titleStack.axis = .horizontal
        titleStack.alignment = .center
        titleStack.spacing = 8
        headerContainer.addSubview(titleStack)

        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.contentMode = .scaleAspectFit
        let logo = UIImage(named: "binboy") ?? UIImage(named: "omnibin-logo") ?? UIImage(systemName: "tray.and.arrow.down.fill")
        logoImageView.image = logo
        logoImageView.tintColor = UIColor.label
        titleStack.addArrangedSubview(logoImageView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Add to omnibin"
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleStack.addArrangedSubview(titleLabel)

        // Preview container
        previewContainer.translatesAutoresizingMaskIntoConstraints = false
        previewContainer.backgroundColor = UIColor.systemBackground
        drawerContainer.addSubview(previewContainer)

        // Image preview
        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        previewImageView.contentMode = .scaleAspectFit
        previewImageView.setContentHuggingPriority(.required, for: .vertical)
        previewImageView.setContentCompressionResistancePriority(.required, for: .vertical)
        previewImageView.isHidden = true
        previewContainer.addSubview(previewImageView)

        // Text preview
        previewTextView.translatesAutoresizingMaskIntoConstraints = false
        previewTextView.isEditable = false
        previewTextView.isScrollEnabled = false
        previewTextView.alwaysBounceVertical = true
        previewTextView.showsVerticalScrollIndicator = true
        previewTextView.isSelectable = true
        previewTextView.isUserInteractionEnabled = true
        previewTextView.font = UIFont.systemFont(ofSize: 16)
        previewTextView.textAlignment = .left
        previewTextView.backgroundColor = UIColor.secondarySystemBackground
        previewTextView.layer.cornerRadius = 8
        previewTextView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        previewTextView.isHidden = true
        previewTextView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        previewTextView.setContentCompressionResistancePriority(.required, for: .vertical)
        previewContainer.addSubview(previewTextView)
        
        // URL Preview setup
        urlPreviewContainer.translatesAutoresizingMaskIntoConstraints = false
        urlPreviewContainer.backgroundColor = UIColor.secondarySystemBackground
        urlPreviewContainer.layer.cornerRadius = 8
        urlPreviewContainer.isHidden = true
        previewContainer.addSubview(urlPreviewContainer)
        
        // URL Preview Image
        urlPreviewImageView.translatesAutoresizingMaskIntoConstraints = false
        urlPreviewImageView.contentMode = .scaleAspectFill
        urlPreviewImageView.clipsToBounds = true
        urlPreviewImageView.layer.cornerRadius = 8
        urlPreviewImageView.isHidden = true
        urlPreviewContainer.addSubview(urlPreviewImageView)
        
        // URL Preview Icon
        urlPreviewIconImageView.translatesAutoresizingMaskIntoConstraints = false
        urlPreviewIconImageView.contentMode = .scaleAspectFit
        urlPreviewIconImageView.layer.cornerRadius = 4
        urlPreviewIconImageView.clipsToBounds = true
        urlPreviewIconImageView.isHidden = true
        urlPreviewContainer.addSubview(urlPreviewIconImageView)
        
        // URL Preview Title
        urlPreviewTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        urlPreviewTitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        urlPreviewTitleLabel.textColor = UIColor.label
        urlPreviewTitleLabel.numberOfLines = 2
        urlPreviewTitleLabel.isHidden = true
        urlPreviewContainer.addSubview(urlPreviewTitleLabel)
        
        // URL Preview Description
        urlPreviewDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        urlPreviewDescriptionLabel.font = UIFont.systemFont(ofSize: 14)
        urlPreviewDescriptionLabel.textColor = UIColor.secondaryLabel
        urlPreviewDescriptionLabel.numberOfLines = 3
        urlPreviewDescriptionLabel.isHidden = true
        urlPreviewContainer.addSubview(urlPreviewDescriptionLabel)
        
        // URL Preview Site
        urlPreviewSiteLabel.translatesAutoresizingMaskIntoConstraints = false
        urlPreviewSiteLabel.font = UIFont.systemFont(ofSize: 12)
        urlPreviewSiteLabel.textColor = UIColor.tertiaryLabel
        urlPreviewSiteLabel.numberOfLines = 1
        urlPreviewSiteLabel.isHidden = true
        urlPreviewContainer.addSubview(urlPreviewSiteLabel)

        // Activity + status (inline)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = ""
        statusLabel.textAlignment = .center
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.textColor = UIColor.secondaryLabel
        statusLabel.numberOfLines = 0
        statusLabel.lineBreakMode = .byWordWrapping
        statusLabel.setContentHuggingPriority(.required, for: .horizontal)

        statusStack.translatesAutoresizingMaskIntoConstraints = false
        statusStack.axis = .horizontal
        statusStack.alignment = .center
        statusStack.spacing = 6
        statusStack.setContentHuggingPriority(.required, for: .horizontal)
        statusStack.addArrangedSubview(activityIndicator)
        statusStack.addArrangedSubview(statusLabel)
        drawerContainer.addSubview(statusStack)

        // Count label directly under preview
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.textAlignment = .right
        countLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        countLabel.textColor = UIColor.secondaryLabel
        drawerContainer.addSubview(countLabel)

        // Warning label (separate from loading text)
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        warningLabel.textAlignment = .right
        warningLabel.font = UIFont.systemFont(ofSize: 14)
        warningLabel.textColor = UIColor.systemRed
        warningLabel.numberOfLines = 0
        warningLabel.lineBreakMode = .byWordWrapping
        drawerContainer.addSubview(warningLabel)

        // Bottom logo
        bottomLogoImageView.translatesAutoresizingMaskIntoConstraints = false
        bottomLogoImageView.contentMode = .scaleAspectFit
        bottomLogoImageView.image = UIImage(named: "omnibin-logo6") ?? UIImage(named: "omnibin-logo") ?? UIImage(named: "binboy")
        bottomLogoImageView.setContentHuggingPriority(.required, for: .vertical)
        bottomLogoImageView.setContentHuggingPriority(.required, for: .horizontal)
        bottomLogoImageView.setContentCompressionResistancePriority(.required, for: .vertical)
        bottomLogoImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        drawerContainer.addSubview(bottomLogoImageView)
        // Ensure logo sits behind other content and never overlays the preview
        drawerContainer.sendSubviewToBack(bottomLogoImageView)

        // Layout
        NSLayoutConstraint.activate([
            // Drawer fills width, pinned to bottom like a sheet
            drawerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            drawerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            drawerContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            drawerContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),

            // Header
            headerContainer.topAnchor.constraint(equalTo: drawerContainer.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: drawerContainer.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: drawerContainer.trailingAnchor),
            headerContainer.heightAnchor.constraint(equalToConstant: 56),

            closeButton.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 12),
            closeButton.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36),

            addButton.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -12),
            addButton.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),

            titleStack.centerXAnchor.constraint(equalTo: headerContainer.centerXAnchor),
            titleStack.centerYAnchor.constraint(equalTo: headerContainer.centerYAnchor),

            logoImageView.widthAnchor.constraint(equalToConstant: 20),
            logoImageView.heightAnchor.constraint(equalToConstant: 20),

            // Preview container
            previewContainer.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 12),
            previewContainer.leadingAnchor.constraint(equalTo: drawerContainer.leadingAnchor, constant: 16),
            previewContainer.trailingAnchor.constraint(equalTo: drawerContainer.trailingAnchor, constant: -16),
            previewContainer.bottomAnchor.constraint(equalTo: countLabel.topAnchor, constant: -8),

            // Image preview constraints (height wraps content; avoid extra space)
            previewImageView.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            previewImageView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            previewImageView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            previewImageView.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),

            // Text preview constraints
            previewTextView.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            previewTextView.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            previewTextView.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            previewTextView.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),
            // Allow the text area to collapse fully when content is short
            previewTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 0),
            previewContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 0),
            
            // URL Preview constraints
            urlPreviewContainer.topAnchor.constraint(equalTo: previewContainer.topAnchor),
            urlPreviewContainer.leadingAnchor.constraint(equalTo: previewContainer.leadingAnchor),
            urlPreviewContainer.trailingAnchor.constraint(equalTo: previewContainer.trailingAnchor),
            urlPreviewContainer.bottomAnchor.constraint(equalTo: previewContainer.bottomAnchor),
            
            // URL Preview Image constraints
            urlPreviewImageView.topAnchor.constraint(equalTo: urlPreviewContainer.topAnchor),
            urlPreviewImageView.leadingAnchor.constraint(equalTo: urlPreviewContainer.leadingAnchor),
            urlPreviewImageView.trailingAnchor.constraint(equalTo: urlPreviewContainer.trailingAnchor),
            urlPreviewImageView.heightAnchor.constraint(equalToConstant: 200),
            
            // URL Preview Icon constraints
            urlPreviewIconImageView.leadingAnchor.constraint(equalTo: urlPreviewContainer.leadingAnchor, constant: 12),
            urlPreviewIconImageView.topAnchor.constraint(equalTo: urlPreviewImageView.bottomAnchor, constant: 12),
            urlPreviewIconImageView.widthAnchor.constraint(equalToConstant: 20),
            urlPreviewIconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            // URL Preview Title constraints - will be updated dynamically based on favicon presence
            urlPreviewTitleLabel.trailingAnchor.constraint(equalTo: urlPreviewContainer.trailingAnchor, constant: -12),
            urlPreviewTitleLabel.topAnchor.constraint(equalTo: urlPreviewImageView.bottomAnchor, constant: 12),
            
            // URL Preview Description constraints
            urlPreviewDescriptionLabel.leadingAnchor.constraint(equalTo: urlPreviewContainer.leadingAnchor, constant: 12),
            urlPreviewDescriptionLabel.trailingAnchor.constraint(equalTo: urlPreviewContainer.trailingAnchor, constant: -12),
            urlPreviewDescriptionLabel.topAnchor.constraint(equalTo: urlPreviewTitleLabel.bottomAnchor, constant: 6),
            
            // URL Preview Site constraints
            urlPreviewSiteLabel.leadingAnchor.constraint(equalTo: urlPreviewContainer.leadingAnchor, constant: 12),
            urlPreviewSiteLabel.trailingAnchor.constraint(equalTo: urlPreviewContainer.trailingAnchor, constant: -12),
            urlPreviewSiteLabel.topAnchor.constraint(equalTo: urlPreviewDescriptionLabel.bottomAnchor, constant: 6),
            urlPreviewSiteLabel.bottomAnchor.constraint(equalTo: urlPreviewContainer.bottomAnchor, constant: -12),

            // Count below preview (right aligned)
            countLabel.leadingAnchor.constraint(greaterThanOrEqualTo: drawerContainer.leadingAnchor, constant: 16),
            countLabel.trailingAnchor.constraint(equalTo: drawerContainer.trailingAnchor, constant: -16),

            // Warning right below count
            warningLabel.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 6),
            warningLabel.leadingAnchor.constraint(equalTo: drawerContainer.leadingAnchor, constant: 16),
            warningLabel.trailingAnchor.constraint(equalTo: drawerContainer.trailingAnchor, constant: -16),

            // Activity + status stack now below warning
            statusStack.topAnchor.constraint(equalTo: warningLabel.bottomAnchor, constant: 6),
            statusStack.centerXAnchor.constraint(equalTo: drawerContainer.centerXAnchor),
            statusStack.leadingAnchor.constraint(greaterThanOrEqualTo: drawerContainer.leadingAnchor, constant: 16),
            statusStack.trailingAnchor.constraint(lessThanOrEqualTo: drawerContainer.trailingAnchor, constant: -16),

            // Bottom logo fills remaining space
            bottomLogoImageView.topAnchor.constraint(equalTo: statusStack.bottomAnchor, constant: 8),
            bottomLogoImageView.centerXAnchor.constraint(equalTo: drawerContainer.centerXAnchor),
            bottomLogoImageView.widthAnchor.constraint(lessThanOrEqualToConstant: 160),
            bottomLogoImageView.heightAnchor.constraint(equalToConstant: 64),
            bottomLogoImageView.bottomAnchor.constraint(equalTo: drawerContainer.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
        
        // Set up initial title constraint (will be updated dynamically)
        titleLeadingConstraint = urlPreviewTitleLabel.leadingAnchor.constraint(equalTo: urlPreviewContainer.leadingAnchor, constant: 12)
        titleLeadingConstraint?.isActive = true

        // Start animating while preparing
        activityIndicator.startAnimating()
    }
    
    private func checkAndShowBinLimitWarning() async {
        guard let accessToken = getAccessToken() else { return }
        do {
            let count = try await fetchBinItemCount(accessToken: accessToken)
            if count >= binItemsLimit {
                let message = "Oldest item will be deleted on next add."
                await MainActor.run {
                    self.limitWarningText = message
                    if !self.isProcessing {
                        self.warningLabel.text = message
                        self.warningLabel.isHidden = false
                    }
                }
            await MainActor.run {
                self.countLabel.text = "Items: \(min(count, binItemsLimit)) / \(binItemsLimit)"
                self.countLabel.textColor = count >= binItemsLimit ? UIColor.systemRed : UIColor.secondaryLabel
            }
        } else {
            await MainActor.run {
                self.countLabel.text = "Items: \(count) / \(binItemsLimit)"
                self.countLabel.textColor = UIColor.secondaryLabel
                self.warningLabel.isHidden = true
            }
            }
        } catch {
            // Ignore silently; not critical for sharing flow
        }
    }
    
    private func fetchBinItemCount(accessToken: String) async throws -> Int {
        guard let url = URL(string: "https://www.omnib.in/api/bin") else {
            throw NSError(domain: "ShareExtension", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "ShareExtension", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch bin items"])
        }
        // Response may be { items: [...] } or an array; support both
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let items = obj["items"] as? [Any] {
            return items.count
        }
        if let arr = try? JSONSerialization.jsonObject(with: data) as? [Any] {
            return arr.count
        }
        return 0
    }
    
    private func loadSharedContentForPreview() {
        guard let inputItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = inputItem.attachments, !attachments.isEmpty else {
            Task { @MainActor in
                self.activityIndicator.stopAnimating()
                self.statusLabel.text = "No content to share"
            }
            return
        }

        func firstAttachment(matching type: String) -> NSItemProvider? {
            return attachments.first { $0.hasItemConformingToTypeIdentifier(type) }
        }

        if let provider = firstAttachment(matching: "public.image") {
            provider.loadItem(forTypeIdentifier: "public.image", options: nil) { [weak self] (item, error) in
                guard let self = self else { return }
                if let image = item as? UIImage {
                    Task { @MainActor in
                        self.sharedContent = .image(image)
                        self.updatePreview()
                    }
                } else if let url = item as? URL {
                    // For local file URL, try load data for preview
                    Task {
                        if url.isFileURL, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                            await MainActor.run {
                                self.sharedContent = .image(image)
                            }
                            await self.updatePreview()
                        } else {
                            await MainActor.run {
                                self.sharedContent = .url(url)
                            }
                            await self.updatePreview()
                        }
                    }
                } else {
                    Task { @MainActor in
                        self.activityIndicator.stopAnimating()
                        self.statusLabel.text = "Unsupported image format"
                    }
                }
            }
        } else if let provider = firstAttachment(matching: "public.file-url") {
            provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { [weak self] (item, _) in
                guard let self = self else { return }
                if let url = item as? URL {
                    Task { @MainActor in
                        self.sharedContent = .fileURL(url)
                        self.updatePreview()
                    }
                } else {
                    Task { @MainActor in
                        self.activityIndicator.stopAnimating()
                        self.statusLabel.text = "Failed to read file URL"
                    }
                }
            }
        } else if let provider = firstAttachment(matching: "public.url") {
            provider.loadItem(forTypeIdentifier: "public.url", options: nil) { [weak self] (item, _) in
                guard let self = self else { return }
                if let url = item as? URL {
                    Task { @MainActor in
                        self.sharedContent = url.isFileURL ? .fileURL(url) : .url(url)
                        self.updatePreview()
                    }
                } else {
                    Task { @MainActor in
                        self.activityIndicator.stopAnimating()
                        self.statusLabel.text = "Failed to read URL"
                    }
                }
            }
        } else if let provider = firstAttachment(matching: "public.text") {
            provider.loadItem(forTypeIdentifier: "public.text", options: nil) { [weak self] (item, _) in
                guard let self = self else { return }
                if let text = item as? String {
                    // If the text contains a URL, prefer the URL over the title
                    Task {
                        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
                            let range = NSRange(text.startIndex..<text.endIndex, in: text)
                            if let match = detector.firstMatch(in: text, options: [], range: range), let foundURL = match.url {
                                await MainActor.run {
                                    self.sharedContent = .url(foundURL)
                                }
                                await self.updatePreview()
                                return
                            }
                        }
                        await MainActor.run {
                            self.sharedContent = .text(text)
                        }
                        await self.updatePreview()
                    }
                } else {
                    Task { @MainActor in
                        self.activityIndicator.stopAnimating()
                        self.statusLabel.text = "Failed to read text"
                    }
                }
            }
        } else {
            Task { @MainActor in
                self.activityIndicator.stopAnimating()
                self.statusLabel.text = "Unsupported content"
            }
        }
    }

    @objc private func addTapped() {
        guard !isProcessing else { return }
        guard let sharedContent = sharedContent else { return }
        isProcessing = true
        activityIndicator.startAnimating()
        statusLabel.text = "Adding to omnibin..."
        addButton.isEnabled = false
        closeButton.isEnabled = false

        switch sharedContent {
        case .text(let text):
            addTextToBin(text) { [weak self] success in
                Task { @MainActor in
                    self?.isProcessing = false
                    self?.activityIndicator.stopAnimating()
                    if success {
                        self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                    } else {
                        self?.statusLabel.text = "Failed to add content"
                        self?.addButton.isEnabled = true
                        self?.closeButton.isEnabled = true
                    }
                }
            }
        case .url(let url):
            addURLToBin(url) { [weak self] success in
                Task { @MainActor in
                    self?.isProcessing = false
                    self?.activityIndicator.stopAnimating()
                    if success {
                        self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                    } else {
                        self?.statusLabel.text = "Failed to add content"
                        self?.addButton.isEnabled = true
                        self?.closeButton.isEnabled = true
                    }
                }
            }
        case .image(let image):
            addImageToBin(image) { [weak self] success in
                Task { @MainActor in
                    self?.isProcessing = false
                    self?.activityIndicator.stopAnimating()
                    if success {
                        self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                    } else {
                        self?.statusLabel.text = "Failed to add content"
                        self?.addButton.isEnabled = true
                        self?.closeButton.isEnabled = true
                    }
                }
            }
        case .fileURL(let url):
            addGenericFileFromURL(url) { [weak self] success in
                Task { @MainActor in
                    self?.isProcessing = false
                    self?.activityIndicator.stopAnimating()
                    if success {
                        self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                    } else {
                        self?.statusLabel.text = "Failed to add content"
                        self?.addButton.isEnabled = true
                        self?.closeButton.isEnabled = true
                    }
                }
            }
        }
    }

    @MainActor
    private func updatePreview() {
        activityIndicator.stopAnimating()
        addButton.isEnabled = true

        previewImageView.isHidden = true
        previewTextView.isHidden = true
        urlPreviewContainer.isHidden = true

        guard let sharedContent = sharedContent else {
            statusLabel.text = "No content to preview"
            return
        }

        switch sharedContent {
        case .image(let image):
            // Deactivate text max height for images
            textPreviewMaxHeightConstraint?.isActive = false

            // Update aspect ratio so the container hugs the actual image size
            imageAspectConstraint?.isActive = false
            let ratio = max(0.1, min(CGFloat(image.size.height / image.size.width), 5.0))
            imageAspectConstraint = previewImageView.heightAnchor.constraint(equalTo: previewImageView.widthAnchor, multiplier: ratio)
            // Lower the priority so it can yield to the max-height cap without constraint conflicts
            imageAspectConstraint?.priority = .defaultHigh
            imageAspectConstraint?.isActive = true

            // Cap image preview container height to 50% of screen to avoid overlapping status/count area
            imagePreviewMaxHeightConstraint?.isActive = false
            imagePreviewMaxHeightConstraint = previewContainer.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.5)
            imagePreviewMaxHeightConstraint?.priority = .required
            imagePreviewMaxHeightConstraint?.isActive = true

            previewImageView.image = image
            previewImageView.isHidden = false
            previewTextView.isHidden = true
        case .text(let text):
            // Cap text preview container height to 50% of screen
            textPreviewMaxHeightConstraint?.isActive = false
            textPreviewMaxHeightConstraint = previewContainer.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.5)
            textPreviewMaxHeightConstraint?.priority = .required
            textPreviewMaxHeightConstraint?.isActive = true

            imageAspectConstraint?.isActive = false
            previewTextView.isHidden = false
            previewTextView.text = text
            adjustTextHeightToContent()
            previewTextView.setContentOffset(.zero, animated: false)
        case .url(let url):
            // Hide other previews
            previewImageView.isHidden = true
            previewTextView.isHidden = true
            urlPreviewContainer.isHidden = false
            
            // Start fetching OpenGraph data
            Task {
                await fetchOpenGraphData(for: url)
            }
            
            // Show loading state
            if isOGLoading {
                urlPreviewTitleLabel.text = "Loading preview..."
                urlPreviewTitleLabel.isHidden = false
                urlPreviewDescriptionLabel.isHidden = true
                urlPreviewSiteLabel.isHidden = true
                urlPreviewImageView.isHidden = true
                urlPreviewIconImageView.isHidden = true
            } else if let ogData = ogData {
                // Show OpenGraph data
                let hasImage = ogData.image != nil
                
                if let imageURLString = ogData.image, let imageURL = URL(string: imageURLString) {
                    urlPreviewImageView.isHidden = false
                    loadImage(from: imageURL, into: urlPreviewImageView)
                } else {
                    urlPreviewImageView.isHidden = true
                }
                
                // Only show favicon if there's no image (same as web and iOS)
                if !hasImage, let iconURLString = ogData.icon, let iconURL = URL(string: iconURLString) {
                    urlPreviewIconImageView.isHidden = false
                    loadImage(from: iconURL, into: urlPreviewIconImageView)
                    // Title should be positioned after the favicon
                    titleLeadingConstraint?.isActive = false
                    titleLeadingConstraint = urlPreviewTitleLabel.leadingAnchor.constraint(equalTo: urlPreviewIconImageView.trailingAnchor, constant: 8)
                    titleLeadingConstraint?.isActive = true
                } else {
                    urlPreviewIconImageView.isHidden = true
                    // Title should be left-aligned when no favicon
                    titleLeadingConstraint?.isActive = false
                    titleLeadingConstraint = urlPreviewTitleLabel.leadingAnchor.constraint(equalTo: urlPreviewContainer.leadingAnchor, constant: 12)
                    titleLeadingConstraint?.isActive = true
                }
                
                urlPreviewTitleLabel.text = ogData.title ?? url.host ?? url.absoluteString
                urlPreviewTitleLabel.isHidden = false
                
                if let description = ogData.description, !description.isEmpty {
                    urlPreviewDescriptionLabel.text = description
                    urlPreviewDescriptionLabel.isHidden = false
                } else {
                    urlPreviewDescriptionLabel.isHidden = true
                }
                
                urlPreviewSiteLabel.text = ogData.siteName ?? url.host ?? ""
                urlPreviewSiteLabel.isHidden = false
            } else {
                // Fallback to showing URL
                urlPreviewTitleLabel.text = url.absoluteString
                urlPreviewTitleLabel.isHidden = false
                urlPreviewDescriptionLabel.isHidden = true
                urlPreviewSiteLabel.text = url.host ?? ""
                urlPreviewSiteLabel.isHidden = false
                urlPreviewImageView.isHidden = true
                urlPreviewIconImageView.isHidden = true
                // Title should be left-aligned when no favicon
                titleLeadingConstraint?.isActive = false
                titleLeadingConstraint = urlPreviewTitleLabel.leadingAnchor.constraint(equalTo: urlPreviewContainer.leadingAnchor, constant: 12)
                titleLeadingConstraint?.isActive = true
            }
        case .fileURL(let url):
            textPreviewMaxHeightConstraint?.isActive = false
            textPreviewMaxHeightConstraint = previewContainer.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.5)
            textPreviewMaxHeightConstraint?.priority = .required
            textPreviewMaxHeightConstraint?.isActive = true

            imageAspectConstraint?.isActive = false
            previewTextView.isHidden = false
            previewTextView.text = url.lastPathComponent
            adjustTextHeightToContent()
            previewTextView.setContentOffset(.zero, animated: false)
        }
        // Clear any transient "ready" messaging once preview is visible
        if let warning = limitWarningText, !warning.isEmpty {
            warningLabel.text = warning
            warningLabel.isHidden = false
        } else {
            warningLabel.text = ""
            warningLabel.isHidden = true
        }
    }

    private func adjustTextHeightToContent() {
        // Measure text and set height so box hugs content up to a cap; enable scroll beyond cap
        let horizontalInsets: CGFloat = 0
        var fittingWidth = previewTextView.bounds.width - horizontalInsets
        if fittingWidth <= 0 {
            fittingWidth = drawerContainer.bounds.width - 32
        }
        let size = previewTextView.sizeThatFits(CGSize(width: fittingWidth, height: CGFloat.greatestFiniteMagnitude))
        let maxHeight = view.bounds.height * 0.35
        let finalHeight = min(size.height, maxHeight)
        previewTextView.isScrollEnabled = size.height > maxHeight

        previewTextHeightConstraint?.isActive = false
        previewTextHeightConstraint = previewTextView.heightAnchor.constraint(equalToConstant: max(0, finalHeight))
        previewTextHeightConstraint?.priority = .required
        previewTextHeightConstraint?.isActive = true
        previewTextView.layoutIfNeeded()
    }
    
    @objc private func cancelTapped() {
        extensionContext?.cancelRequest(withError: NSError(domain: "ShareExtension", code: -1, userInfo: [NSLocalizedDescriptionKey: "User cancelled"]))
    }
    
    private func processContent(completion: @escaping (Bool) -> Void) {
        // Get attachments
        guard let inputItem = extensionContext?.inputItems.first as? NSExtensionItem else {
            completion(false)
            return
        }
        
        // Process attachments
        guard let attachments = inputItem.attachments, !attachments.isEmpty else {
            completion(false)
            return
        }
        
        // Process the first attachment
        let attachment = attachments[0]
        
        // Check for image first (most common case for Photos sharing)
        if attachment.hasItemConformingToTypeIdentifier("public.image") {
            attachment.loadItem(forTypeIdentifier: "public.image", options: nil) { [weak self] (item, error) in
                if error != nil {
                    completion(false)
                    return
                }
                
                if let image = item as? UIImage {
                    self?.addImageToBin(image, completion: completion)
                } else if let url = item as? URL {
                    self?.addImageFromURL(url, completion: completion)
                } else if let data = item as? Data {
                    self?.addImageFromData(data, completion: completion)
                } else {
                    completion(false)
                }
            }
        } else if attachment.hasItemConformingToTypeIdentifier("public.url") {
            attachment.loadItem(forTypeIdentifier: "public.url", options: nil) { [weak self] (item, error) in
                if let url = item as? URL {
                    self?.addURLToBin(url, completion: completion)
                } else {
                    completion(false)
                }
            }
        } else {
            // Try to get as text
            attachment.loadItem(forTypeIdentifier: "public.text", options: nil) { [weak self] (item, error) in
                if let text = item as? String {
                    self?.addTextToBin(text, completion: completion)
                } else {
                    completion(false)
                }
            }
        }
    }
    
    private func addTextToBin(_ text: String, completion: @escaping (Bool) -> Void) {
        // Get access token from shared container
        guard let accessToken = getAccessToken() else {
            Task { @MainActor in
                self.statusLabel.text = "Not logged in"
                self.activityIndicator.stopAnimating()
            }
            completion(false)
            return
        }
        
        // Make API call to add text item
        Task {
            do {
                let _ = try await addTextItemToAPI(content: text, accessToken: accessToken)
                await callCompletion(true, completion: completion)
            } catch {
                await self.setStatusAndStopAnimating("Upload failed")
                await callCompletion(false, completion: completion)
            }
        }
    }
    
    private func addURLToBin(_ url: URL, completion: @escaping (Bool) -> Void) {
        // Add URL as text for now
        addTextToBin(url.absoluteString, completion: completion)
    }
    
    private func fetchOpenGraphData(for url: URL) async {
        guard let accessToken = getAccessToken() else { return }
        
        await MainActor.run {
            isOGLoading = true
        }
        
        do {
            let ogData = try await fetchOpenGraph(url: url.absoluteString, accessToken: accessToken)
            await MainActor.run {
                self.ogData = ogData
                self.isOGLoading = false
            }
            await self.updatePreview()
        } catch {
            await MainActor.run {
                self.isOGLoading = false
            }
            await self.updatePreview()
        }
    }
    
    private func fetchOpenGraph(url: String, accessToken: String) async throws -> OGData {
        guard let apiURL = URL(string: "https://www.omnib.in/api/og") else {
            throw NSError(domain: "ShareExtension", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["url": url]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "ShareExtension", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            throw NSError(domain: "ShareExtension", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode) - \(responseString)"])
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let ogData = json?["og"] as? [String: Any] else {
            throw NSError(domain: "ShareExtension", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid OG data"])
        }
        
        return OGData(
            url: ogData["url"] as? String,
            title: ogData["title"] as? String,
            description: ogData["description"] as? String,
            image: ogData["image"] as? String,
            imageWidth: ogData["imageWidth"] as? Int,
            imageHeight: ogData["imageHeight"] as? Int,
            icon: ogData["icon"] as? String,
            siteName: ogData["siteName"] as? String
        )
    }
    
    private func addImageToBin(_ image: UIImage, completion: @escaping (Bool) -> Void) {
        // Get access token from shared container
        guard let accessToken = getAccessToken() else {
            Task { @MainActor in
                self.statusLabel.text = "Not logged in"
                self.activityIndicator.stopAnimating()
            }
            completion(false)
            return
        }
        
        let usePNG: Bool = {
            guard let alphaInfo = image.cgImage?.alphaInfo else { return false }
            switch alphaInfo {
            case .first, .last, .premultipliedFirst, .premultipliedLast:
                return true
            default:
                return false
            }
        }()
        let imageData: Data?
        let contentType: String
        let fileExtension: String
        if usePNG, let data = image.pngData() {
            imageData = data
            contentType = "image/png"
            fileExtension = "png"
        } else {
            imageData = image.jpegData(compressionQuality: 0.8)
            contentType = "image/jpeg"
            fileExtension = "jpg"
        }
        guard let imageData else {
            Task { @MainActor in
                self.statusLabel.text = "Failed to process image"
                self.activityIndicator.stopAnimating()
            }
            completion(false)
            return
        }
        
        // Check if image data is too large
        let maxSize = 10 * 1024 * 1024 // 10MB
        if imageData.count > maxSize {
            Task { @MainActor in
                self.statusLabel.text = "Image too large"
                self.activityIndicator.stopAnimating()
            }
            completion(false)
            return
        }
        
        // Get image dimensions
        let imageWidth = Int(image.size.width)
        let imageHeight = Int(image.size.height)
        
        // Generate a filename
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "shared_image_\(timestamp).\(fileExtension)"
        
        // Make API call to add file item
        Task {
            do {
                let _ = try await addFileItemToAPI(
                    fileData: imageData,
                    originalName: filename,
                    contentType: contentType,
                    imageWidth: imageWidth,
                    imageHeight: imageHeight,
                    accessToken: accessToken
                )
                await callCompletion(true, completion: completion)
            } catch {
                await self.setStatusAndStopAnimating("Upload failed")
                await callCompletion(false, completion: completion)
            }
        }
    }
    
    private func addImageFromURL(_ url: URL, completion: @escaping (Bool) -> Void) {
        // Get access token from shared container
        guard getAccessToken() != nil else {
            DispatchQueue.main.async {
                self.statusLabel.text = "Not logged in"
                self.activityIndicator.stopAnimating()
            }
            completion(false)
            return
        }
        
        // Check if it's a local file URL (from Photos app)
        if url.isFileURL {
            loadLocalImage(from: url, completion: completion)
        } else {
            loadRemoteImage(from: url, completion: completion)
        }
    }

    private func addGenericFileFromURL(_ url: URL, completion: @escaping (Bool) -> Void) {
        // Upload arbitrary file contents using security-scoped URL
        guard let accessToken = getAccessToken() else {
            DispatchQueue.main.async {
                self.statusLabel.text = "Not logged in"
                self.activityIndicator.stopAnimating()
            }
            completion(false)
            return
        }

        Task {
            do {
                var data: Data?
                var contentType = "application/octet-stream"
                let originalName = url.lastPathComponent

                if url.isFileURL {
                    let gained = url.startAccessingSecurityScopedResource()
                    defer {
                        if gained { url.stopAccessingSecurityScopedResource() }
                    }
                    data = try Data(contentsOf: url)

                    if #available(iOS 14.0, *) {
                        if let utType = UTType(filenameExtension: url.pathExtension) {
                            contentType = utType.preferredMIMEType ?? contentType
                        }
                    }
                } else {
                    let (remoteData, response) = try await URLSession.shared.data(from: url)
                    _ = response
                    data = remoteData
                }

                guard let fileData = data else {
                    await self.setStatusAndStopAnimating("Failed to read file")
                    completion(false)
                    return
                }

                let _ = try await self.addFileItemToAPI(
                    fileData: fileData,
                    originalName: originalName,
                    contentType: contentType,
                    imageWidth: nil,
                    imageHeight: nil,
                    accessToken: accessToken
                )
                await self.callCompletion(true, completion: completion)
            } catch {
                await self.setStatusAndStopAnimating("Upload failed")
                completion(false)
            }
        }
    }
    
    private func loadLocalImage(from url: URL, completion: @escaping (Bool) -> Void) {
        Task {
            do {
                // For local files, we need to use the security-scoped URL
                let securityScopedResource = url.startAccessingSecurityScopedResource()
                defer {
                    if securityScopedResource {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                let data = try Data(contentsOf: url)
                
                guard let image = UIImage(data: data) else {
                    await self.setStatusAndStopAnimating("Invalid image data")
                    completion(false)
                    return
                }
                
                // Update UI on main actor
                await self.callAddImage(image, completion: completion)
                
            } catch {
                await self.setStatusAndStopAnimating("Failed to load image")
                completion(false)
            }
        }
    }
    
    private func loadRemoteImage(from url: URL, completion: @escaping (Bool) -> Void) {
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    await self.setStatusAndStopAnimating("Failed to load image")
                    completion(false)
                    return
                }
                
                guard let image = UIImage(data: data) else {
                    await self.setStatusAndStopAnimating("Invalid image data")
                    completion(false)
                    return
                }
                
                // Update UI on main actor
                await self.callAddImage(image, completion: completion)
                
            } catch {
                await self.setStatusAndStopAnimating("Failed to load image")
                completion(false)
            }
        }
    }
    
    private func addImageFromData(_ data: Data, completion: @escaping (Bool) -> Void) {
        guard let image = UIImage(data: data) else {
            Task { @MainActor in
                self.statusLabel.text = "Invalid image data"
                self.activityIndicator.stopAnimating()
            }
            completion(false)
            return
        }
        
        addImageToBin(image, completion: completion)
    }
    
    private func addImageURLToBin(_ url: URL, completion: @escaping (Bool) -> Void) {
        // Add image URL as text
        addTextToBin(url.absoluteString, completion: completion)
    }
    
    // MARK: - MainActor helpers
    @MainActor
    private func setStatusAndStopAnimating(_ message: String) async {
        self.statusLabel.text = message
        self.activityIndicator.stopAnimating()
    }

    @MainActor
    private func callCompletion(_ success: Bool, completion: @escaping (Bool) -> Void) async {
        completion(success)
    }

    @MainActor
    private func callAddImage(_ image: UIImage, completion: @escaping (Bool) -> Void) async {
        self.addImageToBin(image, completion: completion)
    }
    
    private func loadImage(from url: URL, into imageView: UIImageView) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        imageView.image = image
                    }
                }
            } catch {
                // Image loading failed, keep imageView hidden
            }
        }
    }
    // MARK: - API Integration
    
    private func getAccessToken() -> String? {
        // Try keychain first
        let token = SecureStorageManager.shared.getAccessToken()
        if let token = token {
            return token
        }
        
        // Fallback to UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.in.omnib.omnibin")
        return sharedDefaults?.string(forKey: "access_token")
    }
    
    private func addTextItemToAPI(content: String, accessToken: String) async throws -> BinItem {
        guard let url = URL(string: "https://www.omnib.in/api/bin") else {
            throw NSError(domain: "ShareExtension", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["content": content]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "ShareExtension", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            throw NSError(domain: "ShareExtension", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode) - \(responseString)"])
        }
        
        // Parse response to BinItem; tolerate empty or non-JSON bodies (e.g., 201/204)
        if data.isEmpty {
            return BinItem(
                id: UUID().uuidString,
                createdAt: "",
                textItem: TextItem(content: content),
                fileItem: nil
            )
        }

        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            if let itemData = json {
                return BinItem(
                    id: itemData["id"] as? String ?? UUID().uuidString,
                    createdAt: itemData["createdAt"] as? String ?? "",
                    textItem: TextItem(content: content),
                    fileItem: nil
                )
            } else {
                return BinItem(
                    id: UUID().uuidString,
                    createdAt: "",
                    textItem: TextItem(content: content),
                    fileItem: nil
                )
            }
        } catch {
            return BinItem(
                id: UUID().uuidString,
                createdAt: "",
                textItem: TextItem(content: content),
                fileItem: nil
            )
        }
    }
    
    private func addFileItemToAPI(fileData: Data, originalName: String, contentType: String, imageWidth: Int?, imageHeight: Int?, accessToken: String) async throws -> BinItem {
        guard let url = URL(string: "https://www.omnib.in/api/bin") else {
            throw NSError(domain: "ShareExtension", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // Step 1: Request upload URL from server
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var fileMetadata: [String: Any] = [
            "originalName": originalName,
            "contentType": contentType,
            "size": fileData.count
        ]
        
        // Only add image dimensions if they are valid
        if let width = imageWidth, width > 0 {
            fileMetadata["imageWidth"] = width
        }
        if let height = imageHeight, height > 0 {
            fileMetadata["imageHeight"] = height
        }
        
        let requestBody = ["file": fileMetadata]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "ShareExtension", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            let errorMessage = errorData?["error"] as? String ?? "Unknown error"
            throw NSError(domain: "ShareExtension", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "\(errorMessage) - \(responseString)"])
        }
        
        let responseData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let uploadURLString = responseData?["uploadUrl"] as? String,
              let uploadURL = URL(string: uploadURLString) else {
            throw NSError(domain: "ShareExtension", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid upload URL"])
        }
        
        // Step 2: Upload file to S3
        var uploadRequest = URLRequest(url: uploadURL)
        uploadRequest.httpMethod = "PUT"
        uploadRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        uploadRequest.httpBody = fileData
        
        let (_, uploadResponse) = try await URLSession.shared.data(for: uploadRequest)
        
        guard let uploadHttpResponse = uploadResponse as? HTTPURLResponse else {
            throw NSError(domain: "ShareExtension", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid upload response"])
        }
        
        guard (200...299).contains(uploadHttpResponse.statusCode) else {
            throw NSError(domain: "ShareExtension", code: uploadHttpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to upload file to storage"])
        }
        
        // Step 3: Parse and return the BinItem
        guard let itemData = responseData?["item"] as? [String: Any] else {
            throw NSError(domain: "ShareExtension", code: -5, userInfo: [NSLocalizedDescriptionKey: "Invalid item data"])
        }
        
        // Create a simple BinItem from the response
        return BinItem(
            id: itemData["id"] as? String ?? UUID().uuidString,
            createdAt: itemData["createdAt"] as? String ?? "",
            textItem: nil,
            fileItem: FileItem(
                originalName: originalName,
                contentType: contentType,
                size: fileData.count
            )
        )
    }

}

// MARK: - Simplified Models for Share Extension

struct BinItem {
    let id: String
    let createdAt: String
    let textItem: TextItem?
    let fileItem: FileItem?
}

struct TextItem {
    let content: String
}

struct FileItem {
    let originalName: String
    let contentType: String
    let size: Int
}

struct OGData {
    let url: String?
    let title: String?
    let description: String?
    let image: String?
    let imageWidth: Int?
    let imageHeight: Int?
    let icon: String?
    let siteName: String?
}

// (Quick Look integration removed)