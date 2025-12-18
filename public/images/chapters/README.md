# Chapter Images - Simple Image Folder System

## How to Use

1. **Add images to the folder**: Place your images in `public/images/chapters/`

2. **Link to images in your chapters**: Use simple HTML links in your chapter content:

```html
<a href="/images/chapters/my-photo.jpg" title="My childhood home">Click to view my childhood home</a>
```

Or with an inline thumbnail:

```html
<a href="/images/chapters/family-photo.jpg" title="Family gathering 1985">
  <img src="/images/chapters/family-photo-thumb.jpg" alt="Family photo" style="max-width: 200px;">
</a>
```

## Examples

Put these images in `public/images/chapters/`:
- `childhood-home.jpg`
- `family-1985.jpg` 
- `wedding-day.jpg`
- `graduation.png`

Then in your chapter content, write:

```html
I grew up in <a href="/images/chapters/childhood-home.jpg" title="The house where I spent my childhood">this little house</a> on Maple Street.

Here's <a href="/images/chapters/family-1985.jpg" title="Our family reunion in 1985">our whole family</a> at the big reunion.
```

## Benefits

- ✅ **Simple**: Just drop images in a folder
- ✅ **Fast**: No database queries
- ✅ **Reliable**: Direct file access
- ✅ **Lightbox works perfectly**: Click opens image in overlay
- ✅ **Ctrl+click works**: Opens image in new tab
- ✅ **No conflicts**: Doesn't interfere with gallery system

## File Organization

```
public/images/chapters/
├── chapter-1-childhood.jpg
├── chapter-1-school.jpg
├── chapter-2-wedding.jpg
├── chapter-2-honeymoon.jpg
├── chapter-3-kids.jpg
└── chapter-3-house.jpg
```