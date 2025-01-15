import torch.nn as nn
import torch.nn.functional as F
from PIL import Image
from torchvision import transforms

CLASS_MAP = {
        "0": "A",
        "1": "B",
        "2": "C",
        "3": "D",
        "4": "E",
        "5": "F",
        "6": "G",
        "7": "H",
        "8": "I",
        "9": "J",
        "10": "K",
        "11": "L",
        "12": "M",
        "13": "N",
        "14": "O",
        "15": "P",
        "16": "Q",
        "17": "R",
        "18": "S",
        "19": "T",
        "20": "U",
        "21": "V",
        "22": "W",
        "23": "X",
        "24": "Y",
        "25": "Z"
    }

class CNNBaseModel(nn.Module):
    def __init__(self):
        super(CNNBaseModel, self).__init__()

        # Conv1 - Adding BatchNorm
        self.conv1 = nn.Conv2d(in_channels=1, out_channels=32, kernel_size=(3, 3))
        self.bn1 = nn.BatchNorm2d(32)
        self.pool1 = nn.MaxPool2d(kernel_size=(2, 2))

        # Conv2 - Adding BatchNorm
        self.conv2 = nn.Conv2d(in_channels=32, out_channels=64, kernel_size=(3, 3))
        self.bn2 = nn.BatchNorm2d(64)
        self.pool2 = nn.MaxPool2d(kernel_size=(2, 2))

        # Conv3 - Adding BatchNorm
        self.conv3 = nn.Conv2d(in_channels=64, out_channels=128, kernel_size=(3, 3))
        self.bn3 = nn.BatchNorm2d(128)

        # Dropout Layer
        self.dropout = nn.Dropout(0.5)

        # Fully Connected Layers
        self.flatten = nn.Flatten()
        self.fc1 = nn.Linear(128 * 3 * 3, 256)  # Adjust input size based on the image size after convolutions/pooling
        self.fc2 = nn.Linear(256, 27)  # Output size for 27 classes (softmax)

    def forward(self, x):
        # Conv1 -> BatchNorm -> ReLU -> Pooling
        x = self.conv1(x)
        x = self.bn1(x)
        x = F.relu(x)
        x = self.pool1(x)

        # Conv2 -> BatchNorm -> ReLU -> Pooling
        x = self.conv2(x)
        x = self.bn2(x)
        x = F.relu(x)
        x = self.pool2(x)

        # Conv3 -> BatchNorm -> ReLU
        x = self.conv3(x)
        x = self.bn3(x)
        x = F.relu(x)

        # Flatten
        x = self.flatten(x)

        # Fully Connected Layer 1 with Dropout
        x = self.fc1(x)
        x = F.relu(x)
        x = self.dropout(x)

        # Fully Connected Layer 2
        x = self.fc2(x)

        return x

def preprocess_image():
    """
    img_path is pathlib Path object
    Processes input image (Black pen, white background)
    Returns image tensor formatted for given model
        Resized - 28x28
        Inverted colors
    """
    image = Image.open('cropped_letter.png').convert('L')
    # image = Image.eval(image, lambda x: 255 - x) #Invert colors
    
    transform = transforms.Compose([    #Resize for model and convert to tensor
        transforms.Resize((28, 28)),
        transforms.ToTensor()
    ])
    image_tensor = transform(image)
    image_tensor = image_tensor.unsqueeze(0)

    # if isinstance(model, WaveMix):
    #     image_tensor = image_tensor.repeat(1,3,1,1)
    return image_tensor