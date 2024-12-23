import torch
import torch.nn as nn
import torch.nn.functional as F

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
