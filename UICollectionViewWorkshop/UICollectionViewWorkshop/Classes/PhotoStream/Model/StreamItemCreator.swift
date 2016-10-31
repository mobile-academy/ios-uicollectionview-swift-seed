//
// Copyright (c) 2015 Mobile Academy. All rights reserved.
//

import Foundation
import UIKit

class StreamItemCreator: NSObject, ItemCreating, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    //MARK: Properties

    weak var delegate: ItemCreatingDelegate?

    var controllerPresenter: ViewControllerPresenting
    var resourceAvailability: SourceTypeAvailability
    var actionFactory: AlertActionCreating
    var pickerFactory: ImagePickerCreating
    var imageManipulator: ImageManipulating

    //MARK: Object Life Cycle

    init(presenter: ViewControllerPresenting) {
        controllerPresenter = presenter
        resourceAvailability = DefaultSourceTypeProvider()
        actionFactory = DefaultAlertActionFactory()
        pickerFactory = DefaultImagePickerFactory()
        imageManipulator = DefaultImageManipulator()
    }

    //MARK: ItemCreating

    func createStreamItem() {
        //TODO: Task 2
        //TODO: check the available source types from `resourceAvailability`
        //TODO: if it's empty, inform delegate about error
        //TODO: if it contains single element, present `UIImagePickerController`
        //TODO: if it contains more then one element, present `UIAlertControler` so user has to pick source

        let sources = resourceAvailability.availableSources()
        switch (sources.count) {
            case 0:
                delegate?.creator(self, failedWithError: NSError(domain: "TDDWorkshop", code:-1, userInfo: nil))
            case 1:
                presentPickerWithResourceType(sources.first!)
            default:
                presentSourcesActionSheet(sources)
        }
    }

    //MARK: UIImagePickerControllerDelegate

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String:AnyObject]) {
        controllerPresenter.dismissViewController(picker)
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            let error = NSError(domain: "TDDWorkshop", code: -1, userInfo: nil)
            delegate?.creator(self, failedWithError: error)
            return
        }
        let alertController = createTitleAlertController()
        let alertAction = actionFactory.createActionWithTitle("OK", style: .Default) {
            [weak self] action in
            let title = self?.itemTitleFromTitleAlertController(alertController)
            let streamItem = self?.createItemWithTitle(title!, pickedImage: image)
            self?.delegate?.creator(self!, didCreateItem: streamItem!)
        }
        alertController.addAction(alertAction)
    }

    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        controllerPresenter.dismissViewController(picker)
    }

    //MARK: Private methods

    private func itemTitleFromTitleAlertController(alertController: UIAlertController) -> String {
        guard let title = alertController.textFields?.first?.text else {
            return "No title provided:("
        }
        return title
    }

    private func createItemWithTitle(title: String, pickedImage: UIImage) -> StreamItem {
        let scaledImage = imageManipulator.scaleImage(pickedImage, maxDimension: 500)
        let imageData = imageManipulator.dataFromImage(scaledImage, quality: 0.7)
        let streamItem = StreamItem(title: title, imageData: imageData)
        return streamItem
    }

    private func createTitleAlertController() -> UIAlertController {
        let alertController = UIAlertController(title: "Title of the item", message: nil, preferredStyle: .Alert)
        controllerPresenter.presentViewController(alertController)
        alertController.addTextFieldWithConfigurationHandler {
            textField in
            textField.placeholder = "Something funny"
        }
        return alertController
    }

    private func presentSourcesActionSheet() {
        let alertController = UIAlertController(title: "Add new Item to the stream", message: nil, preferredStyle: .ActionSheet)
        addImagePickerActionsToAlertController(alertController, forSources: resourceAvailability.availableSources())
        let cancelAction = actionFactory.createActionWithTitle("Cancel", style: .Cancel) {
            action in
        }
        alertController.addAction(cancelAction)
        controllerPresenter.presentViewController(alertController)
    }

    private func addImagePickerActionsToAlertController(alertController: UIAlertController,
                                                        forSources sources: [UIImagePickerControllerSourceType]) {
        for source in sources {
            switch (source) {
            case .PhotoLibrary:
                let alertAction = actionFactory.createActionWithTitle("Pick from Library", style: .Default) {
                    [weak self] action in
                    self?.presentPickerWithResourceType(.PhotoLibrary)
                }
                alertController.addAction(alertAction)
            case .Camera:
                let alertAction = actionFactory.createActionWithTitle("Take a Photo", style: .Default) {
                    [weak self] action in
                    self?.presentPickerWithResourceType(.Camera)
                }
                alertController.addAction(alertAction)
            default:
                break
            }
        }
    }

    private func presentPickerWithResourceType(sourceType: UIImagePickerControllerSourceType) {
        let imagePicker = pickerFactory.createPickerWithSourceType(sourceType)
        imagePicker.delegate = self
        controllerPresenter.presentViewController(imagePicker)
    }
}