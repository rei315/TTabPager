import UIKit

extension UICollectionView {
    func dequeueReusableCell<T: UICollectionViewCell>(
        withType type: T.Type, 
        for indexPath: IndexPath
    ) -> T {
        dequeueReusableCell(
            withReuseIdentifier: type.simpleClassName(),
            for: indexPath
        ) as! T
    }

    func registerClass(withType type: (some UICollectionViewCell).Type) {
        register(
            type.self,
            forCellWithReuseIdentifier: type.simpleClassName()
        )
    }
}
