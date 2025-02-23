import cv2
import numpy as np
import time
from bounding_box import BoundingBox
from predictor import Predictor

class FingerTracker:
    def __init__(self):
        self.video_capture = cv2.VideoCapture()
        self.predictor = Predictor()
        self.trace_points = []

        self.lower_orange = np.array([0, 130, 210])  
        self.upper_orange = np.array([20, 240, 255]) 

        self.kernel = np.ones((5, 5), np.uint8)
        
        self.padding = 40
        self.dot_radius = 10
        
        self.gaussian_kernel_size = (self.dot_radius * 3 + 1, self.dot_radius * 3 + 1)
        self.threshold = 127

        self.letters = []
        self.letter_height = 64
        self.current_letter_position = [0, self.letter_height]
        self.letter_position_stack = [self.current_letter_position]

        self.last_command = None
        
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
        self.message = np.zeros((self.frame_height, self.frame_width, 3), dtype=np.uint8)

        self.box = BoundingBox(self.frame_height, self.frame_width, self.padding)

        self.bar_height = self.frame_height - int(self.frame_height / 6)
        self.first_button_edge_x = int(self.frame_width / 4)
        self.second_button_edge_x = int(self.frame_width / 2)
        self.third_button_edge_x = int(self.frame_width / 4 * 3)
        
        cv2.rectangle(self.button_layer, (0, self.bar_height), (self.first_button_edge_x, self.frame_height), (255, 0, 0), -1) # backspace
        cv2.rectangle(self.button_layer, (self.first_button_edge_x, self.bar_height), (self.second_button_edge_x, self.frame_height), (0, 0, 255), -1) # clear
        cv2.rectangle(self.button_layer, (self.second_button_edge_x, self.bar_height), (self.third_button_edge_x, self.frame_height), (0, 255, 0), -1) # accept
        cv2.rectangle(self.button_layer, (self.third_button_edge_x, self.bar_height), (self.frame_width, self.frame_height), (255, 255, 255), -1) # space

        font = cv2.FONT_HERSHEY_COMPLEX_SMALL
        font_scale = 1
        color = (255, 255, 255)
        thickness = 2

        text_height = self.bar_height + (self.frame_height - self.bar_height) // 2
        cv2.putText(self.button_layer, 'backspace', (self.first_button_edge_x // 8, text_height), font, font_scale, color, thickness)
        cv2.putText(self.button_layer, 'clear', (self.first_button_edge_x + self.first_button_edge_x // 3, text_height), font, font_scale, color, thickness)
        cv2.putText(self.button_layer, 'accept', (self.second_button_edge_x + self.first_button_edge_x // 4, text_height), font, font_scale, color, thickness)
        cv2.putText(self.button_layer, 'space', (self.third_button_edge_x + self.first_button_edge_x // 4, text_height), font, font_scale, (0, 0, 0), thickness)

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
        cv2.circle(self.drawing_layer, dot, self.dot_radius, (255, 255, 255), -1)
        cv2.circle(self.canvas, dot, self.dot_radius, (255, 255, 255), -1)
        self.trace_points.append(dot)
        self.box.add_point(dot)

    def save_drawing(self):
        cv2.imwrite('letter.png', self.canvas)

        top = self.box.top - self.dot_radius if self.box.top >= self.dot_radius else self.box.top
        bottom = self.box.bottom + self.dot_radius + 1 if (self.frame_height - self.box.bottom) >= self.dot_radius else self.box.bottom
        left = self.box.left - self.dot_radius if self.box.left >= self.dot_radius else self.box.left
        right = self.box.right + self.dot_radius + 1 if (self.frame_width - self.box.right) >= self.dot_radius else self.box.right

        # isolated_letter = self.canvas[self.box.top:self.box.bottom+1, self.box.left:self.box.right+1]
        isolated_letter = self.canvas[top:bottom, left:right]
        padded_letter = cv2.copyMakeBorder(isolated_letter, self.padding, self.padding, self.padding, self.padding, cv2.BORDER_CONSTANT, value=0)
        cv2.imwrite('padded_letter.png', padded_letter)
        
        blurred_letter = cv2.GaussianBlur(padded_letter, self.gaussian_kernel_size, 0)
        cv2.imwrite('blurred_letter.png', blurred_letter)

        _, thresholded_letter = cv2.threshold(blurred_letter, self.threshold, 255, cv2.THRESH_BINARY)
        cv2.imwrite('thresholded_letter.png', thresholded_letter)

    def add_to_message(self, character):
        self.letters.append(character)

        with open('message.txt', 'a') as file:
            file.write(character)
    
        font = cv2.FONT_HERSHEY_SIMPLEX
        font_scale = 3
        color = (255, 255, 255)
        thickness = 4

        # Get text size
        text_width, text_height = cv2.getTextSize(character, font, font_scale, thickness)[0]

        cv2.putText(self.message, character, self.current_letter_position, font, font_scale, color, thickness)
        self.letter_position_stack.append(self.current_letter_position.copy())

        self.current_letter_position[0] += text_width

        if (self.current_letter_position[0] + text_width) > self.frame_width:
            self.current_letter_position[0] = 0
            self.current_letter_position[1] += self.letter_height + 5

    def predict_letter_trace(self):
        return self.predictor.predict_letter()

    def backspace(self):
        last_letter = self.letters.pop()

        with open("message.txt", "rb+") as file:
            file.seek(0, 2)  
            size = file.tell()  
            if size > 0:
                file.truncate(size - 1) 

        self.current_letter_position = self.letter_position_stack.pop()

        font = cv2.FONT_HERSHEY_SIMPLEX
        font_scale = 3
        color = (0, 0, 0)
        thickness = 4
            
        cv2.putText(self.message, last_letter, self.current_letter_position, font, font_scale, color, thickness)

    def execute_command(self, dot):
        x = dot[0]

        if x < self.first_button_edge_x:
            if len(self.letters) > 0 and self.last_command != 'BACKSPACE':
                self.backspace()

            self.last_command = 'BACKSPACE'
            
        elif x < self.second_button_edge_x:
            if self.has_drawing():
                self.clear_drawing()
            self.last_command = 'CLEAR'
        elif x < self.third_button_edge_x:
            if self.has_drawing():
                self.save_drawing()
                letter = self.predict_letter_trace()
                self.add_to_message(letter)
                self.clear_drawing()
            
            self.last_command = 'SAVE'
        else:
            if self.last_command != 'SPACE':
                self.add_to_message(' ')
                with open('message.txt', 'a') as file:
                    file.write(' ')
            
            self.last_command = 'SPACE'

    def has_drawing(self):
        return len(self.trace_points) != 0

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
        cv2.imshow("Message", self.message)
        cv2.imshow("Mask", self.mask)

    def run(self):
        print('Running program . . .')
        self.start_video_capture()
        self.initialize_screen()
        
        start = time.time()
        processed = False

        while True:
            self.read_frame()
            self.apply_mask()

            dot = self.find_dot_location()
            # print(f"dot: {dot}")
            if self.dot_is_detected(dot):
                if self.is_draw_action(dot):
                    self.add_to_drawing(dot)
                else:
                    self.execute_command(dot)

                start = time.time()
                processed = False
            else:
                self.last_command = None

                if not processed:
                    self.drawing_layer = cv2.GaussianBlur(self.drawing_layer, self.gaussian_kernel_size, 0)
                    _, self.drawing_layer = cv2.threshold(self.drawing_layer, self.threshold, 255, cv2.THRESH_BINARY)
                    processed = True

                if not self.is_drawing_blank():
                    if (time.time() - start) >= 5.0:
                        self.save_drawing()
                        letter = self.predict_letter_trace()
                        self.add_to_message(letter)
                        self.clear_drawing()

            self.display()

            if cv2.pollKey() & 0xFF == ord('q'):
                break

        self.video_capture.release()
        cv2.destroyAllWindows()

if __name__ == "__main__":
    ft = FingerTracker()
    ft.run()
