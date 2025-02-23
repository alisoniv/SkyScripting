import torch
from cnn_base import CNNBaseModel, preprocess_image, CLASS_MAP
from wavemix.classification import WaveMix

class Predictor:
    def __init__(self):
        '''
        self.model = CNNBaseModel()
        state_dict = torch.load('ocr_letters.pth', map_location='cpu', weights_only=True)
        '''

        
        self.model = WaveMix(
            num_classes= 27, 
            depth= 16,
            mult= 2,
            ff_channel= 192,
            final_dim= 112,
            dropout= 0.5,
            level=1,
            patch_size=2,
        )

        state_dict = torch.load('ocr_wavemix_epoch16.pth', map_location='cpu', weights_only=True)
        

        self.model.load_state_dict(state_dict)  
        self.count = 1

    def predict_letter(self):
        self.model.eval()

        '''
        image_tensor = preprocess_image()
        image_tensor = image_tensor * 2 - 1
        '''

        img = preprocess_image()
        # image_tensor = img * 2 - 1
        
        image_tensor = img.repeat(1,3,1,1)
        image_tensor = image_tensor * 2 - 1

        with torch.no_grad():
            # print(image_tensor)
            output = self.model(image_tensor)
            _, predicted_class = torch.max(output, 1)
            predicted_letter = CLASS_MAP[str(predicted_class.item() - 1)]
            print(f"Predicted letter for letter_{self.count}.png: {predicted_letter}")
            # print(f"Predicted letter: {CLASS_MAP[str(predicted_class.item() - 1)]}")
            self.count += 1
            return predicted_letter 