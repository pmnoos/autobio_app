# PDF Export Feature

The Digital Autobiography Template includes powerful PDF export functionality that allows users to create beautiful, printable versions of their life stories.

## Features

### Complete Book Export
- Export your entire autobiography as a single PDF document
- Includes professional cover page with title, author, and generation date
- Automatic table of contents with chapter listings
- Consistent formatting throughout the document

### Individual Chapter Export
- Export any single chapter as a standalone PDF
- Perfect for sharing specific stories with family members
- Maintains professional formatting and styling

## How to Use

### From the Homepage
1. Click the "📄 Download as PDF" button on the main page
2. Your browser will generate and download the complete autobiography

### From the Chapters List
1. Navigate to "Chapters" in the main menu
2. Click "📄 Export Complete Book as PDF" for the full book
3. Or click "📄 Export PDF" next to any individual chapter

### From Individual Chapter Pages
1. Open any chapter by clicking "Read Chapter"
2. Click the "📄 Export as PDF" button at the bottom of the page

## PDF Features

### Professional Styling
- Clean, readable typography using Georgia serif font
- Proper margins and spacing for printing
- Chapter breaks with page separations
- Professional headers and footers with page numbers

### Rich Content Support
- Rich text formatting (bold, italic, lists, quotes)
- Automatic image handling and scaling
- Proper text justification for print quality

### Customizable Information
The PDF includes customizable user information that can be modified in the controller:
- Author name
- Book title and subtitle
- Generation date

## Technical Details

### Dependencies
- `wicked_pdf` gem for PDF generation
- `wkhtmltopdf-binary` for the PDF rendering engine

### Configuration
PDF settings can be customized in the controller methods:
- Page size (default: A4)
- Margins
- Headers and footers
- Print quality settings

## Use Cases

### For Families
- Create physical books for family reunions
- Print chapters as gifts for relatives
- Archive family history in physical format

### For Authors
- Generate manuscript versions for editing
- Create proof copies before publishing
- Share drafts with editors or beta readers

### For Preservation
- Create archival copies of digital memories
- Backup important life stories in physical format
- Ensure stories survive technology changes

## Customization Options

### Styling
The PDF layout can be customized by editing:
- `app/views/layouts/pdf.html.erb` - Main PDF layout and CSS
- `app/views/shared/pdf_header.html.erb` - Header template
- `app/views/shared/pdf_footer.html.erb` - Footer template

### Content Templates
- `app/views/chapters/export_pdf.html.erb` - Complete book template
- `app/views/chapters/export_chapter_pdf.html.erb` - Single chapter template

### User Information
Edit the `get_user_info_for_pdf` method in `ChaptersController` to customize:
- Default author name
- Book title and subtitle
- Additional metadata

## Tips for Best Results

1. **Images**: Images are automatically scaled to fit the page width
2. **Rich Text**: Use the rich text editor features for better formatting
3. **Chapter Order**: Chapters export in the order they appear in the application
4. **File Names**: PDF files are automatically named with timestamps
5. **Print Quality**: Generated PDFs are optimized for both screen viewing and printing

The PDF export feature makes it easy to create beautiful, professional-looking books from your digital autobiography, perfect for sharing with family or preserving your stories for future generations.
