extension UIView {
    @objc func constraintsForPlacingIn(_ other: UIView, insets: UIEdgeInsets = UIEdgeInsets()) -> [NSLayoutConstraint] {
        return [
            self.topAnchor.constraint(equalTo: other.topAnchor, constant: insets.top),
            self.rightAnchor.constraint(equalTo: other.rightAnchor, constant: -insets.right),
            self.bottomAnchor.constraint(equalTo: other.bottomAnchor, constant: -insets.bottom),
            self.leftAnchor.constraint(equalTo: other.leftAnchor, constant: insets.left),
        ]
    }
    @objc(constraintsForPlacingInGuide:insets:)
    func constraintsForPlacingIn(_ guide: UILayoutGuide, insets: UIEdgeInsets = UIEdgeInsets()) -> [NSLayoutConstraint] {
        return [
            self.topAnchor.constraint(equalTo: guide.topAnchor, constant: insets.top),
            self.rightAnchor.constraint(equalTo: guide.rightAnchor, constant: -insets.right),
            self.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -insets.bottom),
            self.leftAnchor.constraint(equalTo: guide.leftAnchor, constant: insets.left),
        ]
    }
}
