import darwin / [app_kit, objc/runtime,  core_graphics/cggeometry]

proc CGRectMake*(x, y, w, h: SomeNumber): CGRect =
  result = CGRect(origin: CGPoint(x: x.CGFloat, y: y.CGFloat), size: CGSize(width: w.CGFloat, height: h.CGFloat))
