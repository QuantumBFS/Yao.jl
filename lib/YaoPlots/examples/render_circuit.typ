// Typst Circuit Renderer for Yao.jl JSON Backend
// Usage: #render-circuit(json-data)

#import "@preview/cetz:0.3.1": canvas, draw

#set page(width: auto, height: auto, margin: 5pt)

#let render-circuit(commands) = {
  // Extract circuit metadata
  let num_qubits = 0
  let gate_count = 0
  
  // Find number of qubits and gates
  for cmd in commands {
    if cmd.at("type") == "gate" {
      gate_count += 1
      for lbt in cmd.at("loc_brush_texts") {
        let qubits = lbt.at("qubits")
        if qubits.len() > 0 {
          num_qubits = calc.max(num_qubits, ..qubits.map(q => q + 1))
        }
      }
    } else if cmd.at("type") in ("textbottom", "texttop") {
      num_qubits = calc.max(num_qubits, cmd.at("qubit") + 1)
    }
  }
  
  let unit = 40  // Unit size in pt
  let gate_width = 0.8
  let gate_spacing = 0.3
  
  canvas(length: unit * 1pt, {
    import draw: *
    
    // Draw qubit lines
    let circuit_length = gate_count * (gate_width + gate_spacing) + 2
    for q in range(num_qubits) {
      line((0, q), (circuit_length, q))
    }
    
    // Track current column position
    let col = 1.0
    
    // Render commands
    for cmd in commands {
      let cmd_type = cmd.at("type")
      
      if cmd_type == "gate" {
        let loc_brush_texts = cmd.at("loc_brush_texts")
        
        // Find qubit range for this gate
        let all_qubits = ()
        for lbt in loc_brush_texts {
          all_qubits += lbt.at("qubits")
        }
        
        if all_qubits.len() == 0 {
          continue
        }
        
        let min_q = calc.min(..all_qubits)
        let max_q = calc.max(..all_qubits)
        let mid_q = (min_q + max_q) / 2
        
        // Draw gates for each loc_brush_text entry
        for lbt in loc_brush_texts {
          let qubits = lbt.at("qubits")
          let text_str = lbt.at("text")
          let brush = lbt.at("brush")
          
          if qubits.len() == 0 {
            continue
          }
          
          // Determine gate type from brush
          let is_dot = brush.contains("Dot")
          let is_ndot = brush.contains("NDot") 
          let is_cross = brush.contains("Cross")
          let is_oplus = brush.contains("OPlus")
          let is_box = brush.contains("Box")
          let is_measure = brush.contains("MeasureBox")
          
          if is_dot {
            // Control dot
            for q in qubits {
              circle((col, q), radius: 0.1, fill: black, stroke: none)
            }
          } else if is_ndot {
            // Negative control (open circle)
            for q in qubits {
              circle((col, q), radius: 0.15, fill: white)
            }
          } else if is_cross {
            // SWAP cross
            for q in qubits {
              line((col - 0.15, q - 0.15), (col + 0.15, q + 0.15))
              line((col - 0.15, q + 0.15), (col + 0.15, q - 0.15))
            }
          } else if is_oplus {
            // Controlled-X (target)
            for q in qubits {
              circle((col, q), radius: 0.25, fill: white)
              line((col - 0.25, q), (col + 0.25, q))
              line((col, q - 0.25), (col, q + 0.25))
            }
          } else if is_measure {
            // Measurement box
            for q in qubits {
              rect((col - 0.4, q - 0.3), (col + 0.4, q + 0.3), fill: white)
              //arc((col, q), start: 0deg, end: 180deg, radius: 0.4, stroke: black)
              line((col, q - 0.2), (col + 0.3, q + 0.1), stroke: black)
              arc((col + 0.3, q - 0.2), start: 0deg, delta: 180deg, radius: 0.3, stroke: black)
            }
          } else {
            // Regular gate box
            let q_min = calc.min(..qubits)
            let q_max = calc.max(..qubits)
            let q_mid = (q_min + q_max) / 2
            let height = q_max - q_min + 0.6
            
            rect(
              (col - gate_width/2, q_mid - height/2),
              (col + gate_width/2, q_mid + height/2),
              fill: white
            )
            
            content(
              (col, q_mid),
              text(text_str, size: 10pt),
              anchor: "center"
            )
          }
        }
        
        // Draw vertical line connecting multi-qubit gates
        if min_q != max_q {
          line((col, min_q), (col, max_q))
        }
        
        // Advance column
        col += gate_width + gate_spacing
      } else if cmd_type == "textbottom" {
        // Annotation below gate (use previous column position)
        let q = cmd.at("qubit")
        let txt = cmd.at("text")
        content(
          (col - gate_width/2 - gate_spacing/2, q + 0.5),
          text(txt, size: 8pt, fill: blue),
          anchor: "center"
        )
      } else if cmd_type == "texttop" {
        // Annotation above gate (use previous column position)
        let q = cmd.at("qubit")
        let txt = cmd.at("text")
        content(
          (col - gate_width/2 - gate_spacing/2, q - 0.5),
          text(txt, size: 8pt, fill: blue),
          anchor: "center"
        )
      }
    }
    
    // Add qubit labels on the left
    for q in range(num_qubits) {
      content(
        (-0.5, q),
        text([$q_#q$], size: 10pt),
        anchor: "east"
      )
    }
  })
}
