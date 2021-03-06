import Quick
import Nimble

@testable
import UICollectionViewWorkshop

class StreamItemCreatorSpec: QuickSpec {
    override func spec() {
        describe("StreamItemCreator") {

            var sut: StreamItemCreator!

            var testDelegate: TestStreamItemCreatorDelegate!

            var presenter: ViewControllerPresenterFake!
            var resourceAvailability: SourceTypeAvailabilityFake!
            var alertActionFactory: AlertActionFactoryFake!
            var pickerFactory: ImagePickerFactoryFake!
            var imageManipulator: ImageManipulatorFake!

            beforeEach {
                presenter = ViewControllerPresenterFake()
                resourceAvailability = SourceTypeAvailabilityFake()
                alertActionFactory = AlertActionFactoryFake()
                pickerFactory = ImagePickerFactoryFake()
                imageManipulator = ImageManipulatorFake()

                sut = StreamItemCreator(presenter: presenter)
                sut.resourceAvailability = resourceAvailability
                sut.actionFactory = alertActionFactory
                sut.pickerFactory = pickerFactory
                sut.imageManipulator = imageManipulator

                testDelegate = TestStreamItemCreatorDelegate()
                sut.delegate = testDelegate
            }

            describe("create item") {

                context("when no source is available") {
                    beforeEach {
                        resourceAvailability.fakeSources = []
                        sut.createStreamItem()
                    }
                    it("should NOT present alert controller") {
                        expect(presenter.capturedPresentedViewController as? UIAlertController).to(beNil())
                    }
                    it("should NOT present image picker controller") {
                        expect(presenter.capturedPresentedViewController as? UIImagePickerController).to(beNil())
                    }
                    it("should inform delegate about failure") {
                        expect(testDelegate.failedWithErrorCalled) == true
                    }
                }

                context("when photo library is only available") {
                   beforeEach {
                       resourceAvailability.fakeSources = [.photoLibrary]
                       sut.createStreamItem()
                    }
                    it("should NOT present alert controller") {
                        expect(presenter.capturedPresentedViewController as? UIAlertController).to(beNil())
                    }
                    it("should present image picker controller") {
                        expect(presenter.capturedPresentedViewController as? UIImagePickerController).notTo(beNil())
                    }
                    it("should present picker with Camera source type") {
                        expect(pickerFactory.capturedSourceType!) == UIImagePickerControllerSourceType.photoLibrary
                    }
                }

                context("when camera is only available") {
                   beforeEach {
                       resourceAvailability.fakeSources = [.camera]
                       sut.createStreamItem()
                    }
                    it("should NOT present alert controller") {
                        expect(presenter.capturedPresentedViewController as? UIAlertController).to(beNil())
                    }
                    it("should present image picker controller") {
                        expect(presenter.capturedPresentedViewController as? UIImagePickerController).notTo(beNil())
                    }
                    it("should present picker with Camera source type") {
                        expect(pickerFactory.capturedSourceType!) == UIImagePickerControllerSourceType.camera
                    }
                }

                context("when photo library and camera are available") {
                    beforeEach {
                        resourceAvailability.fakeSources = [.photoLibrary, .camera]
                        sut.createStreamItem()
                    }
                    it("should present alert controller") {
                        expect(presenter.capturedPresentedViewController as? UIAlertController).notTo(beNil())
                    }
                    it("should present alert controller with action sheet style") {
                        let alertController = presenter.capturedPresentedViewController as! UIAlertController
                        expect(alertController.preferredStyle) == UIAlertControllerStyle.actionSheet
                    }
                    it("should present alert controller with title 'Add new Item to the stream'") {
                        let alertController = presenter.capturedPresentedViewController as! UIAlertController
                        expect(alertController.title) == "Add new Item to the stream"
                    }
                    it("should have 3 alert actions") {
                        expect(alertActionFactory.capturedActions.count) == 3
                    }
                    it("should present alert controller with 1st option 'Pick from Library'") {
                        let alertAction = alertActionFactory.capturedActions[0]
                        expect(alertAction.title) == "Pick from Library"
                    }
                    it("should present alert controller with 1st option set to Default style") {
                        let alertAction = alertActionFactory.capturedActions[0]
                        expect(alertAction.style) == UIAlertActionStyle.default
                    }
                    it("should present alert controller with 2nd option 'Take a Photo'") {
                        let alertAction = alertActionFactory.capturedActions[1]
                        expect(alertAction.title) == "Take a Photo"
                    }
                    it("should present alert controller with 2nd option set to Default style") {
                        let alertAction = alertActionFactory.capturedActions[1]
                        expect(alertAction.style) == UIAlertActionStyle.default
                    }
                    it("should present alert controller with 3rd option 'Cancel'") {
                        let alertAction = alertActionFactory.capturedActions[2]
                        expect(alertAction.title) == "Cancel"
                    }
                    it("should present alert controller with 3rd option set to Cancel style") {
                        let alertAction = alertActionFactory.capturedActions[2]
                        expect(alertAction.style) == UIAlertActionStyle.cancel
                    }

                    context("when user selects") {
                        beforeEach {
                            presenter.capturedPresentedViewController = nil
                        }
                        context("first option") {
                            beforeEach {
                                let action = alertActionFactory.capturedActions[0]
                                let handler = alertActionFactory.capturedHandlers[0]
                                handler(action)
                            }
                            it("should present image picker") {
                                expect(presenter.capturedPresentedViewController as? UIImagePickerController).notTo(beNil())
                            }
                            it("should present picker with Photo Library source type") {
                                expect(pickerFactory.capturedSourceType!) == UIImagePickerControllerSourceType.photoLibrary
                            }
                        }
                        context("second option") {
                            beforeEach {
                                let action = alertActionFactory.capturedActions[1]
                                let handler = alertActionFactory.capturedHandlers[1]
                                handler(action)
                            }
                            it("should present image picker") {
                                expect(presenter.capturedPresentedViewController as? UIImagePickerController).notTo(beNil())
                            }
                            it("should present picker with Camera source type") {
                                expect(pickerFactory.capturedSourceType!) == UIImagePickerControllerSourceType.camera
                            }
                        }
                        context("third option") {
                            beforeEach {
                                let action = alertActionFactory.capturedActions[2]
                                let handler = alertActionFactory.capturedHandlers[2]
                                handler(action)
                            }
                            it("should NOT present image picker") {
                                expect(presenter.capturedPresentedViewController as? UIImagePickerController).to(beNil())
                            }
                        }
                    }
                }

                describe("image picker controller delegate") {

                    var picker: UIImagePickerController!
                    var image: UIImage!

                    beforeEach {
                        picker = UIImagePickerController()
                        image = UIImage()
                    }

                    context("did pick media") {
                        beforeEach {
                            sut.imagePickerController(picker,
                                    didFinishPickingMediaWithInfo: [UIImagePickerControllerOriginalImage: image])
                        }
                        it("should dismiss image picker") {
                            expect(presenter.capturedDismissedViewController as? UIImagePickerController).notTo(beNil())
                        }
                        it("should present alert controller") {
                            expect(presenter.capturedPresentedViewController as? UIAlertController).notTo(beNil())
                        }
                        it("should present alert controller with title 'Title of the item'") {
                            let alertController = presenter.capturedPresentedViewController as! UIAlertController
                            expect(alertController.title) == "Title of the item"
                        }
                        it("should present alert controller with action sheet style") {
                            let alertController = presenter.capturedPresentedViewController as! UIAlertController
                            expect(alertController.preferredStyle) == UIAlertControllerStyle.alert
                        }
                        it("should add text field to alert controller") {
                            let alertController = presenter.capturedPresentedViewController as! UIAlertController
                            expect(alertController.textFields).notTo(beNil())
                        }
                        it("should have 1 alert action") {
                            expect(alertActionFactory.capturedActions.count) == 1
                        }
                        it("should present alert controller with 1st option 'OK'") {
                            let alertAction = alertActionFactory.capturedActions[0]
                            expect(alertAction.title) == "OK"
                        }
                        it("should present alert controller with 1st option set to Default style") {
                            let alertAction = alertActionFactory.capturedActions[0]
                            expect(alertAction.style) == UIAlertActionStyle.default
                        }
                        context("when user selects") {
                            beforeEach {
                                let alertController = presenter.capturedPresentedViewController as! UIAlertController
                                let textField = alertController.textFields!.first!
                                textField.text = "Fixture title"
                            }
                            context("first option") {
                                beforeEach {
                                    let action = alertActionFactory.capturedActions[0]
                                    let handler = alertActionFactory.capturedHandlers[0]
                                    handler(action)
                                }
                                it("should scale selected image using Image Manipulator") {
                                    expect(imageManipulator.capturedImageToScale).notTo(beNil())
                                    expect(imageManipulator.capturedImageToScale!) == image
                                }
                                it("should convert scaled image to data") {
                                    expect(imageManipulator.capturedImageToDataConversion).notTo(beNil())
                                    expect(imageManipulator.capturedImageToDataConversion!) == imageManipulator.fakeScaledImage
                                }
                                it("should inform delegate about Stream Item creation") {
                                    expect(testDelegate.capturedStreamItem).notTo(beNil())
                                }
                                it("should create stream item with data of scaled image") {
                                    let item = testDelegate.capturedStreamItem!
                                    expect(item.imageData) == imageManipulator.fakeDataFromImage
                                }
                                it("should create stream item with title provided in the alert") {
                                    let item = testDelegate.capturedStreamItem!
                                    expect(item.title) == "Fixture title"
                                }
                            }
                        }
                    }
                    context("did cancel") {
                        beforeEach {
                            sut.imagePickerControllerDidCancel(picker)
                        }
                        it("should dismiss image picker") {
                            expect(presenter.capturedDismissedViewController as? UIImagePickerController).notTo(beNil())
                        }
                    }
                }
            }
        }
    }
}
