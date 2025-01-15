import cv2
import numpy as np
import time
from cnn_base import CNNBaseModel, preprocess_image, CLASS_MAP
from bounding_box import BoundingBox
import torch

class FingerTracker:
    def __init__(self):
        self.video_capture = cv2.VideoCapture()
        self.lower_orange = np.array([0, 130, 210])  
        self.upper_orange = np.array([25, 240, 255]) 
        self.kernel = np.ones((5, 5), np.uint8)
        self.trace_points = []
        
        self.model = CNNBaseModel()
        state_dict = torch.load('ocr_letters.pth', map_location='cpu', weights_only=True)
        self.model.load_state_dict(state_dict)  
        
    def start_video_capture(self):
        self.video_capture.open(0)

        if not self.video_capture.isOpened():
            raise Exception('Video capture could not be opened!')
        
        self.frame_width = int(self.video_capture.get(cv2.CAP_PROP_FRAME_WIDTH))
        self.frame_height = int(self.video_capture.get(cv2.CAP_PROP_FRAME_HEIGHT))

    def initialize_screen(self):
        self.canvas = np.zeros((self.frame_height, self.frame_width, 3), np.uint8)
        self.drawing_layer = np.zeros((self.frame_height, self.frame_width, 3), np.uint8)
        self.button_layer = np.zeros((self.frame_height, self.frame_width, 3), np.uint8)

        self.box = BoundingBox(self.frame_height, self.frame_width)
        print('Height: ' + str(self.frame_height) + ', Width: ' + str(self.frame_width))

        self.bar_height = self.frame_height - int(self.frame_height / 10)
        self.midpoint_x = int(self.frame_width / 2)

        cv2.rectangle(self.button_layer, (0, self.bar_height), (self.midpoint_x, self.frame_height), (0, 255, 0), -1)
        cv2.rectangle(self.button_layer, (self.midpoint_x, self.bar_height), (self.frame_width, self.frame_height), (0, 0, 255), -1)

    def read_frame(self):
        _, self.frame = self.video_capture.read()
        self.frame = cv2.flip(self.frame, 1)
        self.hsv_frame = cv2.cvtColor(self.frame, cv2.COLOR_BGR2HSV)

    def apply_mask(self):
        self.mask = cv2.inRange(self.hsv_frame, self.lower_orange, self.upper_orange)
        self.mask = cv2.morphologyEx(self.mask, cv2.MORPH_OPEN, self.kernel)
        self.mask = cv2.morphologyEx(self.mask, cv2.MORPH_CLOSE, self.kernel)

    def find_dot_location(self):
        contours, _ = cv2.findContours(self.mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        
        if contours:
            largest_contour = max(contours, key = cv2.contourArea)
            if cv2.contourArea(largest_contour) > 20: 
                M = cv2.moments(largest_contour)
                if M["m00"] != 0:
                    cx = int(M["m10"] / M["m00"])
                    cy = int(M["m01"] / M["m00"])
                    return (cx, cy)
        
        return (-1, -1)
    
    def dot_is_detected(self, dot):
        return dot != (-1, -1)

    def is_draw_action(self, dot):
        return dot[1] < self.bar_height

    def add_to_drawing(self, dot):
        cv2.circle(self.drawing_layer, dot, 8, (255, 255, 255), -1)
        cv2.circle(self.canvas, dot, 8, (255, 255, 255), -1)
        cv2.putText(self.frame, f"Orange Dot: ({dot[0]}, {dot[1]})", (dot[0] + 10, dot[1] - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 2)
        self.trace_points.append(dot)
        self.box.add_point(dot)

    def save_drawing(self):
        cv2.imwrite('letter.png', self.canvas)
        print('Top: ' + str(self.box.top) + ', Bottom: ' + str(self.box.bottom) + ', Left: ' + str(self.box.left) + ', Right: ' + str(self.box.right))
        cropped_letter = self.canvas[self.box.get_top_bound():self.box.get_bottom_bound(), self.box.get_left_bound():self.box.get_right_bound()]
        cv2.imwrite('cropped_letter.png', cropped_letter)

    def execute_command(self, dot):
        if dot[0] < self.midpoint_x and len(self.trace_points) != 0:
            self.save_drawing()
            self.predict_letter()
        
        self.clear_drawing()

    def clear_drawing(self):
        self.canvas = np.zeros((self.frame_height, self.frame_width, 3), np.uint8)
        self.drawing_layer = np.zeros((self.frame_height, self.frame_width, 3), np.uint8)
        self.trace_points.clear()
        self.box.reset()

    def is_drawing_blank(self):
        return len(self.trace_points) == 0

    def display(self):
        cv2.addWeighted(self.frame, 1.0, self.drawing_layer, 1.0, 0, self.frame)
        cv2.addWeighted(self.frame, 1.0, self.button_layer, 1.0, 0, self.frame)
        cv2.imshow("Live Camera", self.frame)
        cv2.imshow("Mask", self.mask)

    def predict_letter(self):
        self.model.eval()

        image_tensor = preprocess_image()
        image_tensor = image_tensor * 2 - 1
        
        with torch.no_grad():
            # print(image_tensor)
            output = self.model(image_tensor)
            _, predicted_class = torch.max(output, 1)
            print('Predicted_class: ' + CLASS_MAP[str(predicted_class.item() - 1)])

    def run(self):
        self.start_video_capture()
        self.initialize_screen()
        
        start = time.time()

        while True:
            self.read_frame()
            self.apply_mask()

            dot = self.find_dot_location()
            if self.dot_is_detected(dot):
                if self.is_draw_action(dot):
                    self.add_to_drawing(dot)
                else:
                    self.execute_command(dot)

                start = time.time()
            else:
                if not self.is_drawing_blank():
                    if (time.time() - start) >= 5.0:
                        self.save_drawing()
                        self.predict_letter()
                        self.clear_drawing()

            self.display()

            if cv2.waitKey(1) & 0xFF == ord('q'):
                break

        self.video_capture.release()
        cv2.destroyAllWindows()

if __name__ == "__main__":
    ft = FingerTracker()
    ft.run()
